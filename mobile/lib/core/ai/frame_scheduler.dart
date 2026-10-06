import 'dart:async';
import '../../domain/entities/performance_settings.dart';

/// Callback signature for inference worker execution
typedef InferenceTask<T> = Future<T> Function(dynamic frame);

/// Decoupled Frame Scheduler for On-Device Plant Recognition.
///
/// Features:
/// - Independent Camera FPS and AI FPS
/// - Single-slot latest frame latch (Zero queue accumulation)
/// - Automatic frame dropping when inference is in-flight or throttled
/// - Live measurement of Camera FPS and AI Inference FPS
/// - Memory-leak free, non-blocking UI thread operation
class FrameScheduler {
  int _targetAiFps;
  bool _isDisposed = false;
  bool _isInferring = false;
  DateTime _lastInferenceTime = DateTime.fromMillisecondsSinceEpoch(0);

  // FPS Metrics tracking
  int _cameraFrameCount = 0;
  int _aiInferenceCount = 0;
  int _droppedFrameCount = 0;
  DateTime _lastMetricTick = DateTime.now();

  double _measuredCameraFps = 0.0;
  double _measuredAiFps = 0.0;
  double _lastInferenceLatencyMs = 0.0;

  // Listeners for telemetry
  void Function(double cameraFps, double aiFps, double latencyMs)? onMetricsUpdate;

  FrameScheduler({int targetAiFps = 15}) : _targetAiFps = targetAiFps;

  int get targetAiFps => _targetAiFps;
  bool get isInferring => _isInferring;
  double get measuredCameraFps => _measuredCameraFps;
  double get measuredAiFps => _measuredAiFps;
  double get lastInferenceLatencyMs => _lastInferenceLatencyMs;
  int get droppedFrames => _droppedFrameCount;

  /// Update the target AI FPS dynamically (e.g. from Settings or Adaptive controller)
  void setTargetAiFps(int fps) {
    if (fps <= 0) return;
    _targetAiFps = fps.clamp(5, 30);
  }

  /// Sets target AI FPS based on settings enum
  void setTargetAiFpsFromOption(AiInferenceFps option) {
    switch (option) {
      case AiInferenceFps.auto:
        _targetAiFps = 15;
        break;
      case AiInferenceFps.fps5:
        _targetAiFps = 5;
        break;
      case AiInferenceFps.fps10:
        _targetAiFps = 10;
        break;
      case AiInferenceFps.fps15:
        _targetAiFps = 15;
        break;
      case AiInferenceFps.fps20:
        _targetAiFps = 20;
        break;
      case AiInferenceFps.fps30:
        _targetAiFps = 30;
        break;
    }
  }

  /// Ingest an incoming camera frame.
  /// Returns `true` if frame was dispatched for inference, `false` if dropped.
  Future<bool> processFrame<T>({
    required dynamic frame,
    required Future<T> Function(dynamic frame) inferenceWorker,
    required void Function(T result) onResult,
    void Function(Object error)? onError,
  }) async {
    if (_isDisposed) return false;

    final now = DateTime.now();
    _cameraFrameCount++;
    _updateMetricsIfIntervalElapsed(now);

    // 1. Frame Dropping Rule A: In-flight concurrency lock
    if (_isInferring) {
      _droppedFrameCount++;
      return false;
    }

    // 2. Frame Dropping Rule B: Target FPS throttling interval
    final intervalMs = (1000 / _targetAiFps).round();
    final elapsedSinceLastInference = now.difference(_lastInferenceTime).inMilliseconds;
    if (elapsedSinceLastInference < intervalMs) {
      _droppedFrameCount++;
      return false;
    }

    // 3. Dispatch frame
    _isInferring = true;
    _lastInferenceTime = now;
    final stopwatch = Stopwatch()..start();

    try {
      final result = await inferenceWorker(frame);
      stopwatch.stop();

      if (!_isDisposed) {
        _lastInferenceLatencyMs = stopwatch.elapsedMilliseconds.toDouble();
        _aiInferenceCount++;
        onResult(result);
      }
      return true;
    } catch (e) {
      stopwatch.stop();
      if (!_isDisposed && onError != null) {
        onError(e);
      }
      return false;
    } finally {
      _isInferring = false;
    }
  }

  void _updateMetricsIfIntervalElapsed(DateTime now) {
    final elapsedMs = now.difference(_lastMetricTick).inMilliseconds;
    if (elapsedMs >= 1000) {
      final seconds = elapsedMs / 1000.0;
      _measuredCameraFps = _cameraFrameCount / seconds;
      _measuredAiFps = _aiInferenceCount / seconds;

      _cameraFrameCount = 0;
      _aiInferenceCount = 0;
      _lastMetricTick = now;

      onMetricsUpdate?.call(_measuredCameraFps, _measuredAiFps, _lastInferenceLatencyMs);
    }
  }

  void reset() {
    _isInferring = false;
    _cameraFrameCount = 0;
    _aiInferenceCount = 0;
    _droppedFrameCount = 0;
    _measuredCameraFps = 0.0;
    _measuredAiFps = 0.0;
    _lastInferenceLatencyMs = 0.0;
    _lastInferenceTime = DateTime.fromMillisecondsSinceEpoch(0);
    _lastMetricTick = DateTime.now();
  }

  void dispose() {
    _isDisposed = true;
  }
}
