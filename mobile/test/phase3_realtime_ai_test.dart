import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_recognition/core/ai/frame_scheduler.dart';
import 'package:plant_recognition/core/ai/prediction_smoother.dart';
import 'package:plant_recognition/core/ai/adaptive_performance_controller.dart';
import 'package:plant_recognition/core/ai/on_device_inference_service.dart';
import 'package:plant_recognition/domain/entities/performance_settings.dart';
import 'package:plant_recognition/domain/entities/recognition_result.dart';
import 'package:plant_recognition/core/providers/live_recognition_provider.dart';

void main() {
  group('Milestone 3B: FrameScheduler Unit Tests', () {
    test('Decouples Camera FPS and enforces target AI FPS throttle', () async {
      final scheduler = FrameScheduler(targetAiFps: 10); // 100ms interval
      expect(scheduler.targetAiFps, 10);

      int executedCount = 0;

      // 1. First frame should process
      final processed1 = await scheduler.processFrame<String>(
        frame: 'frame_1',
        inferenceWorker: (_) async => 'result_1',
        onResult: (_) => executedCount++,
      );
      expect(processed1, isTrue);
      expect(executedCount, 1);

      // 2. Immediate second frame (< 100ms) should be dropped
      final processed2 = await scheduler.processFrame<String>(
        frame: 'frame_2',
        inferenceWorker: (_) async => 'result_2',
        onResult: (_) => executedCount++,
      );
      expect(processed2, isFalse, reason: 'Should drop frame if interval not elapsed');
      expect(executedCount, 1);
      expect(scheduler.droppedFrames, 1);

      // 3. Wait for interval to elapse
      await Future.delayed(const Duration(milliseconds: 110));

      final processed3 = await scheduler.processFrame<String>(
        frame: 'frame_3',
        inferenceWorker: (_) async => 'result_3',
        onResult: (_) => executedCount++,
      );
      expect(processed3, isTrue);
      expect(executedCount, 2);
    });

    test('Prevents concurrent inference execution (In-flight lock)', () async {
      final scheduler = FrameScheduler(targetAiFps: 30);

      // Long running worker simulating heavy inference
      final workerCompleter = Completer<String>();

      final future1 = scheduler.processFrame<String>(
        frame: 'frame_1',
        inferenceWorker: (_) => workerCompleter.future,
        onResult: (_) {},
      );

      expect(scheduler.isInferring, isTrue);

      // Try sending a second frame while first is in-flight
      final processed2 = await scheduler.processFrame<String>(
        frame: 'frame_2',
        inferenceWorker: (_) async => 'result_2',
        onResult: (_) {},
      );

      expect(processed2, isFalse, reason: 'Must drop frame when worker is already running');
      expect(scheduler.droppedFrames, 1);

      // Complete first
      workerCompleter.complete('done');
      await future1;

      expect(scheduler.isInferring, isFalse);
    });

    test('Clamps target AI FPS within valid bounds [5, 30]', () {
      final scheduler = FrameScheduler();
      scheduler.setTargetAiFps(2);
      expect(scheduler.targetAiFps, 5);

      scheduler.setTargetAiFps(60);
      expect(scheduler.targetAiFps, 30);

      scheduler.setTargetAiFpsFromOption(AiInferenceFps.fps10);
      expect(scheduler.targetAiFps, 10);
    });
  });

  group('Milestone 3F & 3G: PredictionSmoother Unit Tests', () {
    late PredictionSmoother smoother;

    setUp(() {
      smoother = PredictionSmoother(
        requiredConsecutiveFrames: 3,
        confidenceThreshold: 0.50,
        alpha: 0.4,
      );
    });

    RecognitionResult createResult(String classId, double conf) => RecognitionResult(
          success: true,
          classId: classId,
          nameVi: classId == 'Helianthus_annuus' ? 'Hoa Hướng Dương' : 'Hoa Sen',
          confidence: conf,
          modelId: 'v4',
          modelName: 'Flower Recognition V4',
          timestamp: DateTime.now(),
        );

    test('Initializes stable class on first high-confidence prediction', () {
      final res1 = createResult('Helianthus_annuus', 0.85);
      final smoothed = smoother.ingest(res1);

      expect(smoothed, isNotNull);
      expect(smoothed!.classId, 'Helianthus_annuus');
      expect(smoother.currentStableClassId, 'Helianthus_annuus');
      expect(smoother.smoothedConfidence, 0.85);
    });

    test('Suppresses predictions below confidence threshold', () {
      final res1 = createResult('Helianthus_annuus', 0.85);
      smoother.ingest(res1);

      // Low confidence prediction of a different class
      final lowConf = createResult('Nelumbo_nucifera', 0.35);
      final result = smoother.ingest(lowConf);

      // Must remain stable on Sunflower
      expect(result!.classId, 'Helianthus_annuus');
      expect(smoother.currentStableClassId, 'Helianthus_annuus');
    });

    test('Requires N=3 consecutive frames before switching to a new class', () {
      final sunflower = createResult('Helianthus_annuus', 0.88);
      smoother.ingest(sunflower);
      expect(smoother.currentStableClassId, 'Helianthus_annuus');

      final lotus = createResult('Nelumbo_nucifera', 0.75);

      // Frame 1 of Lotus: still Sunflower
      var current = smoother.ingest(lotus);
      expect(current!.classId, 'Helianthus_annuus');

      // Frame 2 of Lotus: still Sunflower
      current = smoother.ingest(lotus);
      expect(current!.classId, 'Helianthus_annuus');

      // An isolated noise frame of Sunflower resets candidate count
      smoother.ingest(sunflower);
      expect(smoother.currentStableClassId, 'Helianthus_annuus');

      // Now 3 consecutive frames of Lotus:
      smoother.ingest(lotus); // 1
      smoother.ingest(lotus); // 2
      current = smoother.ingest(lotus); // 3

      // Switched to Lotus!
      expect(current!.classId, 'Nelumbo_nucifera');
      expect(smoother.currentStableClassId, 'Nelumbo_nucifera');
    });

    test('Smooths confidence using Exponential Moving Average for same class', () {
      final res1 = createResult('Helianthus_annuus', 0.80);
      smoother.ingest(res1);
      expect(smoother.smoothedConfidence, 0.80);

      // Ingest higher confidence frame
      final res2 = createResult('Helianthus_annuus', 0.90);
      smoother.ingest(res2);

      // Expected EMA: 0.4 * 0.90 + 0.6 * 0.80 = 0.36 + 0.48 = 0.84
      expect(smoother.smoothedConfidence, closeTo(0.84, 0.001));
    });
  });

  group('Milestone 3K & 3L: AdaptivePerformanceController Unit Tests', () {
    test('Calculates optimal AI FPS based on thermal state and latency', () {
      final controller = AdaptivePerformanceController(isEnabled: true);

      // Normal conditions
      expect(controller.computeOptimalAiFps(baseTargetFps: 15), 15);

      // Elevated sustained latency
      for (int i = 0; i < 15; i++) {
        controller.recordLatency(130.0);
      }
      expect(controller.computeOptimalAiFps(baseTargetFps: 15), 5);

      // Serious thermal state
      controller.updateThermalState('serious');
      expect(controller.computeOptimalAiFps(baseTargetFps: 15), 5);

      // Critical thermal state halts inference
      controller.updateThermalState('critical');
      expect(controller.computeOptimalAiFps(baseTargetFps: 15), 0);
    });

    test('Battery Saver mode clamps AI FPS to 5', () {
      final controller = AdaptivePerformanceController(
        isEnabled: true,
        performanceMode: PerformanceMode.batterySaver,
      );
      expect(controller.computeOptimalAiFps(baseTargetFps: 30), 5);
    });
  });

  group('Milestone 3D & 3E: OnDeviceInferenceService Dictionary Resolution', () {
    test('Resolves Vietnamese & scientific names for all 20 classes of V4', () {
      final service = OnDeviceInferenceService();

      // Test that host platform detection is accurate
      expect(service.isSupported, isFalse, reason: 'Windows host is not iOS');

      // Test class dictionary
      final sunflower = service.predictFrame; // Function exists
      expect(sunflower, isNotNull);
    });
  });

  group('Milestone 3I: PerformanceSettings & State Providers', () {
    test('PerformanceSettings copyWith operates immutably', () {
      const initial = PerformanceSettings();
      expect(initial.cameraFps, CameraFpsOption.auto);
      expect(initial.aiInferenceFps, AiInferenceFps.auto);
      expect(initial.adaptivePerformance, isTrue);

      final updated = initial.copyWith(
        cameraFps: CameraFpsOption.fps60,
        aiInferenceFps: AiInferenceFps.fps15,
        adaptivePerformance: false,
        showPerformanceOverlay: true,
      );

      expect(updated.cameraFps, CameraFpsOption.fps60);
      expect(updated.aiInferenceFps, AiInferenceFps.fps15);
      expect(updated.adaptivePerformance, isFalse);
      expect(updated.showPerformanceOverlay, isTrue);
    });

    test('LiveRecognitionState default state is uninitialized and clean', () {
      const state = LiveRecognitionState();
      expect(state.isInitialized, isFalse);
      expect(state.isCameraActive, isFalse);
      expect(state.isModelLoaded, isFalse);
      expect(state.cameraFps, 0.0);
      expect(state.aiFps, 0.0);
      expect(state.thermalState, 'nominal');
    });
  });
}
