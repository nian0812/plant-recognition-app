import '../../domain/entities/performance_settings.dart';

enum DeviceThermalState { nominal, fair, serious, critical }

/// Adaptive Performance and Thermal Management Controller.
///
/// Features:
/// - Throttles AI FPS independently of Camera FPS based on latency & thermals
/// - Prevents overheating and battery drain
/// - Integrates with iPhone ProcessInfo.thermalState
class AdaptivePerformanceController {
  final bool isEnabled;
  final PerformanceMode performanceMode;
  DeviceThermalState _thermalState = DeviceThermalState.nominal;

  double _movingAvgLatencyMs = 35.0;
  static const double _latencyAlpha = 0.2;

  AdaptivePerformanceController({
    this.isEnabled = true,
    this.performanceMode = PerformanceMode.auto,
  });

  DeviceThermalState get thermalState => _thermalState;
  double get averageLatencyMs => _movingAvgLatencyMs;

  void updateThermalState(String stateString) {
    switch (stateString.toLowerCase().trim()) {
      case 'critical':
        _thermalState = DeviceThermalState.critical;
        break;
      case 'serious':
        _thermalState = DeviceThermalState.serious;
        break;
      case 'fair':
        _thermalState = DeviceThermalState.fair;
        break;
      case 'nominal':
      default:
        _thermalState = DeviceThermalState.nominal;
        break;
    }
  }

  void recordLatency(double latencyMs) {
    _movingAvgLatencyMs = (_latencyAlpha * latencyMs) + ((1.0 - _latencyAlpha) * _movingAvgLatencyMs);
  }

  /// Calculates dynamically adapted AI FPS without degrading camera smoothness
  int computeOptimalAiFps({required int baseTargetFps}) {
    // 1. Performance mode overrides
    if (performanceMode == PerformanceMode.batterySaver) {
      return 5;
    }
    if (performanceMode == PerformanceMode.highPerformance) {
      return baseTargetFps.clamp(15, 30);
    }

    if (!isEnabled) {
      return baseTargetFps;
    }

    // 2. Critical thermal shutdown
    if (_thermalState == DeviceThermalState.critical) {
      return 0; // Pause inference to cool down
    }

    // 3. Thermal throttling
    if (_thermalState == DeviceThermalState.serious) {
      return 5;
    }
    if (_thermalState == DeviceThermalState.fair) {
      return baseTargetFps > 10 ? 10 : baseTargetFps;
    }

    // 4. Latency-driven throttling
    if (_movingAvgLatencyMs > 120.0) {
      return 5;
    } else if (_movingAvgLatencyMs > 75.0) {
      return baseTargetFps > 10 ? 10 : baseTargetFps;
    }

    return baseTargetFps;
  }
}
