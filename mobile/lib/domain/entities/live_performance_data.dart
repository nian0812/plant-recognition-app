/// Real-time performance overlay data for live camera mode.
class LivePerformanceData {
  final double cameraFps;
  final double aiFps;
  final double inferenceTimeMs;
  final String modelName;
  final String inputSize;
  final String engine;
  final double? confidence;
  final String? thermalState;

  const LivePerformanceData({
    this.cameraFps = 0,
    this.aiFps = 0,
    this.inferenceTimeMs = 0,
    this.modelName = '',
    this.inputSize = '',
    this.engine = 'N/A',
    this.confidence,
    this.thermalState,
  });
}
