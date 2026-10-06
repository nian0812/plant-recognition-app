import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/recognition_result.dart';
import '../../domain/entities/performance_settings.dart';
import '../ai/frame_scheduler.dart';
import '../ai/prediction_smoother.dart';
import '../ai/adaptive_performance_controller.dart';
import '../ai/on_device_inference_service.dart';
import 'app_providers.dart';

/// State of the live on-device plant recognition session
class LiveRecognitionState {
  final bool isInitialized;
  final bool isCameraActive;
  final bool isModelLoaded;
  final bool isInferring;
  final RecognitionResult? smoothedResult;
  final RecognitionResult? rawResult;
  final double cameraFps;
  final double aiFps;
  final double latencyMs;
  final String thermalState;
  final String hardwareEngine;
  final CameraLensDirection lensDirection;
  final bool isFlashOn;
  final int currentTargetAiFps;
  final String? errorMessage;

  const LiveRecognitionState({
    this.isInitialized = false,
    this.isCameraActive = false,
    this.isModelLoaded = false,
    this.isInferring = false,
    this.smoothedResult,
    this.rawResult,
    this.cameraFps = 0.0,
    this.aiFps = 0.0,
    this.latencyMs = 0.0,
    this.thermalState = 'nominal',
    this.hardwareEngine = 'Core ML — Automatic',
    this.lensDirection = CameraLensDirection.back,
    this.isFlashOn = false,
    this.currentTargetAiFps = 15,
    this.errorMessage,
  });

  LiveRecognitionState copyWith({
    bool? isInitialized,
    bool? isCameraActive,
    bool? isModelLoaded,
    bool? isInferring,
    RecognitionResult? smoothedResult,
    RecognitionResult? rawResult,
    double? cameraFps,
    double? aiFps,
    double? latencyMs,
    String? thermalState,
    String? hardwareEngine,
    CameraLensDirection? lensDirection,
    bool? isFlashOn,
    int? currentTargetAiFps,
    String? errorMessage,
  }) {
    return LiveRecognitionState(
      isInitialized: isInitialized ?? this.isInitialized,
      isCameraActive: isCameraActive ?? this.isCameraActive,
      isModelLoaded: isModelLoaded ?? this.isModelLoaded,
      isInferring: isInferring ?? this.isInferring,
      smoothedResult: smoothedResult ?? this.smoothedResult,
      rawResult: rawResult ?? this.rawResult,
      cameraFps: cameraFps ?? this.cameraFps,
      aiFps: aiFps ?? this.aiFps,
      latencyMs: latencyMs ?? this.latencyMs,
      thermalState: thermalState ?? this.thermalState,
      hardwareEngine: hardwareEngine ?? this.hardwareEngine,
      lensDirection: lensDirection ?? this.lensDirection,
      isFlashOn: isFlashOn ?? this.isFlashOn,
      currentTargetAiFps: currentTargetAiFps ?? this.currentTargetAiFps,
      errorMessage: errorMessage,
    );
  }
}

final onDeviceInferenceServiceProvider = Provider<OnDeviceInferenceService>((ref) {
  return OnDeviceInferenceService();
});

final liveRecognitionProvider =
    StateNotifierProvider.autoDispose<LiveRecognitionNotifier, LiveRecognitionState>((ref) {
  final inferenceService = ref.watch(onDeviceInferenceServiceProvider);
  final performanceSettings = ref.watch(performanceSettingsProvider);

  return LiveRecognitionNotifier(
    inferenceService: inferenceService,
    performanceSettings: performanceSettings,
  );
});

class LiveRecognitionNotifier extends StateNotifier<LiveRecognitionState> {
  final OnDeviceInferenceService _inferenceService;
  final PerformanceSettings _performanceSettings;

  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = [];
  int _selectedCameraIndex = 0;

  late final FrameScheduler _frameScheduler;
  late final PredictionSmoother _smoother;
  late final AdaptivePerformanceController _adaptiveController;

  Timer? _thermalPollTimer;

  LiveRecognitionNotifier({
    required OnDeviceInferenceService inferenceService,
    required PerformanceSettings performanceSettings,
  })  : _inferenceService = inferenceService,
        _performanceSettings = performanceSettings,
        super(const LiveRecognitionState()) {
    _frameScheduler = FrameScheduler(targetAiFps: 15);
    _smoother = PredictionSmoother(
      requiredConsecutiveFrames: 3,
      confidenceThreshold: 0.50,
      alpha: 0.35,
    );
    _adaptiveController = AdaptivePerformanceController(
      isEnabled: performanceSettings.adaptivePerformance,
      performanceMode: performanceSettings.performanceMode,
    );

    _frameScheduler.setTargetAiFpsFromOption(performanceSettings.aiInferenceFps);

    _frameScheduler.onMetricsUpdate = (camFps, aiFps, latency) {
      if (mounted) {
        _adaptiveController.recordLatency(latency);
        final optimalFps = _adaptiveController.computeOptimalAiFps(
          baseTargetFps: _frameScheduler.targetAiFps,
        );

        state = state.copyWith(
          cameraFps: camFps,
          aiFps: aiFps,
          latencyMs: latency,
          currentTargetAiFps: optimalFps,
        );
      }
    };
  }

  CameraController? get cameraController => _cameraController;

  /// Starts the camera and on-device Core ML model
  Future<void> startSession({String modelId = 'v4'}) async {
    try {
      state = state.copyWith(errorMessage: null);

      // 1. Initialize On-Device Model
      final modelLoaded = await _inferenceService.initialize(modelId: modelId);
      state = state.copyWith(
        isModelLoaded: modelLoaded,
        hardwareEngine: _inferenceService.hardwareEngine,
      );

      // 2. Query available physical cameras
      try {
        _availableCameras = await availableCameras();
      } catch (e) {
        debugPrint('[LiveRecognitionNotifier] Physical camera query skipped: $e');
        _availableCameras = [];
      }
      if (_availableCameras.isEmpty) {
        state = state.copyWith(
          isInitialized: true,
          isCameraActive: false,
          errorMessage: 'Không tìm thấy camera khả dụng trên thiết bị.',
        );
        return;
      }

      // Default to rear camera
      _selectedCameraIndex = _availableCameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (_selectedCameraIndex < 0) _selectedCameraIndex = 0;

      await _initializeCameraController();

      // 3. Start thermal polling on iOS
      _thermalPollTimer?.cancel();
      _thermalPollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
        final thermal = await _inferenceService.getThermalState();
        _adaptiveController.updateThermalState(thermal);
        if (mounted) {
          state = state.copyWith(thermalState: thermal);
        }
      });
    } catch (e) {
      state = state.copyWith(
        isInitialized: true,
        errorMessage: 'Lỗi khởi động camera: $e',
      );
    }
  }

  Future<void> _initializeCameraController() async {
    final camera = _availableCameras[_selectedCameraIndex];

    final ResolutionPreset preset;
    switch (_performanceSettings.cameraResolution) {
      case CameraResolution.hd:
        preset = ResolutionPreset.medium;
        break;
      case CameraResolution.fullHd:
        preset = ResolutionPreset.high;
        break;
      case CameraResolution.highest:
        preset = ResolutionPreset.veryHigh;
        break;
      case CameraResolution.auto:
        preset = ResolutionPreset.medium;
        break;
    }

    _cameraController = CameraController(
      camera,
      preset,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.bgra8888,
    );

    await _cameraController!.initialize();

    // Start streaming frames
    await _cameraController!.startImageStream((CameraImage image) {
      _onCameraFrame(image);
    });

    state = state.copyWith(
      isInitialized: true,
      isCameraActive: true,
      lensDirection: camera.lensDirection,
    );
  }

  void _onCameraFrame(CameraImage image) {
    _frameScheduler.processFrame<RecognitionResult?>(
      frame: image,
      inferenceWorker: (frame) async {
        if (!_inferenceService.isModelLoaded) return null;

        // Extract bytes from first plane
        final bytes = (frame as CameraImage).planes.first.bytes;
        return await _inferenceService.predictFrame(
          frameBytes: bytes,
          width: frame.width,
          height: frame.height,
        );
      },
      onResult: (rawResult) {
        if (rawResult != null && mounted) {
          final smoothed = _smoother.ingest(rawResult);
          state = state.copyWith(
            rawResult: rawResult,
            smoothedResult: smoothed ?? rawResult,
          );
        }
      },
      onError: (err) {
        debugPrint('[LiveRecognitionNotifier] Frame inference error: $err');
      },
    );
  }

  /// Flip between back and front camera
  Future<void> switchCamera() async {
    if (_availableCameras.length < 2) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _availableCameras.length;
    await _cameraController?.stopImageStream();
    await _cameraController?.dispose();
    _cameraController = null;

    await _initializeCameraController();
  }

  /// Toggle torch / flash
  Future<void> toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final nextState = !state.isFlashOn;
      await _cameraController!.setFlashMode(nextState ? FlashMode.torch : FlashMode.off);
      state = state.copyWith(isFlashOn: nextState);
    } catch (_) {}
  }

  /// App lifecycle paused: stop camera stream
  Future<void> onAppPaused() async {
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      await _cameraController?.stopImageStream();
      state = state.copyWith(isCameraActive: false);
    }
  }

  /// App lifecycle resumed: restart camera stream
  Future<void> onAppResumed() async {
    if (_cameraController != null && !_cameraController!.value.isStreamingImages) {
      await _cameraController?.startImageStream(_onCameraFrame);
      state = state.copyWith(isCameraActive: true);
    }
  }

  @override
  void dispose() {
    _thermalPollTimer?.cancel();
    _frameScheduler.dispose();
    _cameraController?.dispose();
    _inferenceService.dispose();
    super.dispose();
  }
}
