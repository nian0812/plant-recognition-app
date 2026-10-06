enum CameraFpsOption { auto, fps30, fps60 }
enum AiInferenceFps { auto, fps5, fps10, fps15, fps20, fps30 }
enum PerformanceMode { auto, highPerformance, balanced, batterySaver }
enum CameraResolution { auto, hd, fullHd, highest }
enum AiEngineType { automatic, coreML, gpu, cpu }

class PerformanceSettings {
  final CameraFpsOption cameraFps;
  final AiInferenceFps aiInferenceFps;
  final PerformanceMode performanceMode;
  final CameraResolution cameraResolution;
  final bool adaptivePerformance;
  final AiEngineType aiEngine;
  final bool showPerformanceOverlay;

  const PerformanceSettings({
    this.cameraFps = CameraFpsOption.auto,
    this.aiInferenceFps = AiInferenceFps.auto,
    this.performanceMode = PerformanceMode.auto,
    this.cameraResolution = CameraResolution.auto,
    this.adaptivePerformance = true,
    this.aiEngine = AiEngineType.automatic,
    this.showPerformanceOverlay = false,
  });

  PerformanceSettings copyWith({
    CameraFpsOption? cameraFps,
    AiInferenceFps? aiInferenceFps,
    PerformanceMode? performanceMode,
    CameraResolution? cameraResolution,
    bool? adaptivePerformance,
    AiEngineType? aiEngine,
    bool? showPerformanceOverlay,
  }) {
    return PerformanceSettings(
      cameraFps: cameraFps ?? this.cameraFps,
      aiInferenceFps: aiInferenceFps ?? this.aiInferenceFps,
      performanceMode: performanceMode ?? this.performanceMode,
      cameraResolution: cameraResolution ?? this.cameraResolution,
      adaptivePerformance: adaptivePerformance ?? this.adaptivePerformance,
      aiEngine: aiEngine ?? this.aiEngine,
      showPerformanceOverlay: showPerformanceOverlay ?? this.showPerformanceOverlay,
    );
  }
}

/// Mock hardware information for UI display.
class AIEngineInfo {
  final String engineName;
  final String status;
  final bool isAvailable;
  final String? deviceInfo;

  const AIEngineInfo({
    required this.engineName,
    required this.status,
    this.isAvailable = false,
    this.deviceInfo,
  });
}
