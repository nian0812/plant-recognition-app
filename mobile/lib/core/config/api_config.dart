import 'package:flutter/foundation.dart';

/// Central API Configuration for Plant Recognition backend integration.
class ApiConfig {
  ApiConfig._();

  static const int defaultPort = 5217;
  static const int httpsPort = 7293;

  /// Default Base URL dynamically chosen based on runtime platform:
  /// - Android Emulator: http://10.0.2.2:5217
  /// - Windows / Web: http://localhost:5217
  /// - iOS Simulator / macOS / Linux: http://localhost:5217
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:5217';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5217';
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return 'http://localhost:5217';
    }
  }

  // Network timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 60);

  // Endpoints
  static const String modelsEndpoint = '/api/Model';
  static String modelDetailEndpoint(String modelId) => '/api/Model/$modelId';
  static String modelClassesEndpoint(String modelId) =>
      '/api/Model/$modelId/classes';
  static String predictEndpoint(String modelId) =>
      '/api/Recognition/predict?modelId=$modelId';
}
