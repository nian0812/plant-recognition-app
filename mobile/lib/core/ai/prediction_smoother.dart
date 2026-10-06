import '../../domain/entities/recognition_result.dart';

/// Temporal smoothing filter for live real-time camera predictions.
///
/// Features:
/// - Eliminates frame-by-frame flicker between classes
/// - Exponential Moving Average (EMA) confidence filtering
/// - Requires N consecutive frames of a new class before state transition
/// - Configurable confidence threshold (default: 0.50)
class PredictionSmoother {
  final int requiredConsecutiveFrames;
  final double confidenceThreshold;
  final double alpha; // Smoothing factor for EMA (0.0 < alpha <= 1.0)

  String? _currentStableClassId;
  RecognitionResult? _currentStableResult;
  double _smoothedConfidence = 0.0;

  String? _candidateClassId;
  int _candidateCount = 0;

  PredictionSmoother({
    this.requiredConsecutiveFrames = 3,
    this.confidenceThreshold = 0.50,
    this.alpha = 0.35,
  });

  RecognitionResult? get currentStableResult => _currentStableResult;
  String? get currentStableClassId => _currentStableClassId;
  double get smoothedConfidence => _smoothedConfidence;

  /// Ingest raw inference prediction and produce a stabilized, smoothed result.
  RecognitionResult? ingest(RecognitionResult rawResult) {
    if (!rawResult.success) {
      return _currentStableResult;
    }

    final rawConfidence = rawResult.confidence;
    final incomingClassId = rawResult.classId;

    // 1. If confidence is below threshold, ignore candidate switch
    if (rawConfidence < confidenceThreshold) {
      _candidateCount = 0;
      _candidateClassId = null;
      return _currentStableResult;
    }

    // 2. If it matches current stable class, update smoothed confidence via EMA
    if (incomingClassId == _currentStableClassId) {
      _smoothedConfidence = (alpha * rawConfidence) + ((1.0 - alpha) * _smoothedConfidence);
      _candidateCount = 0;
      _candidateClassId = null;

      _currentStableResult = _currentStableResult?.copyWith(
        confidence: _smoothedConfidence,
        inferenceTimeMs: rawResult.inferenceTimeMs,
        timestamp: DateTime.now(),
      );
      return _currentStableResult;
    }

    // 3. If it's a new class candidate, require consecutive confirmation
    if (incomingClassId == _candidateClassId) {
      _candidateCount++;
    } else {
      _candidateClassId = incomingClassId;
      _candidateCount = 1;
    }

    // 4. Transition to new stable class once consecutive threshold is satisfied
    if (_candidateCount >= requiredConsecutiveFrames || _currentStableClassId == null) {
      _currentStableClassId = incomingClassId;
      _smoothedConfidence = rawConfidence;
      _currentStableResult = rawResult.copyWith(
        confidence: _smoothedConfidence,
        timestamp: DateTime.now(),
      );
      _candidateCount = 0;
      _candidateClassId = null;
    }

    return _currentStableResult;
  }

  void reset() {
    _currentStableClassId = null;
    _currentStableResult = null;
    _smoothedConfidence = 0.0;
    _candidateClassId = null;
    _candidateCount = 0;
  }
}
