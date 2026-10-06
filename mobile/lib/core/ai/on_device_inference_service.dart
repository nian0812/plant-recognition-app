import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/recognition_result.dart';

/// Service coordinating On-Device AI inference via Apple Core ML.
/// Communicates through MethodChannel with native iOS CoreMLRunner.
class OnDeviceInferenceService {
  static const MethodChannel _channel = MethodChannel('com.plantrecognition.app/coreml');

  bool _isModelLoaded = false;
  String _activeModelId = 'v4';
  String _hardwareEngine = 'Core ML — Automatic';
  Map<String, dynamic> _classMapping = {};

  bool get isModelLoaded => _isModelLoaded;
  String get activeModelId => _activeModelId;
  String get hardwareEngine => _hardwareEngine;
  Map<String, dynamic> get classMapping => _classMapping;

  bool get isSupported => defaultTargetPlatform == TargetPlatform.iOS;

  /// Initialize model and load class mapping
  Future<bool> initialize({String modelId = 'v4'}) async {
    _activeModelId = modelId;

    // 1. Load V4 class mapping from bundled asset
    try {
      final jsonStr = await rootBundle.loadString('assets/models/class_mapping_v4.json');
      _classMapping = json.decode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[OnDeviceInferenceService] Notice: could not load asset class mapping: $e');
    }

    // 2. On iOS, load native Core ML model
    if (isSupported) {
      try {
        final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
          'loadModel',
          {'modelName': 'FlowerRecognitionV4'},
        );
        _isModelLoaded = result?['success'] == true;
        _hardwareEngine = result?['engine'] as String? ?? 'Core ML — Automatic';
        return _isModelLoaded;
      } on PlatformException catch (e) {
        debugPrint('[OnDeviceInferenceService] iOS Core ML load error: $e');
        _isModelLoaded = false;
        return false;
      }
    } else {
      // Non-iOS host platform (e.g. Windows dev / Web test)
      debugPrint('[OnDeviceInferenceService] Running on non-iOS host platform ($defaultTargetPlatform). Native Apple Neural Engine requires iOS.');
      _isModelLoaded = false;
      return false;
    }
  }

  /// Run real on-device inference on a camera image frame
  Future<RecognitionResult> predictFrame({
    required Uint8List frameBytes,
    int width = 384,
    int height = 384,
  }) async {
    if (!isSupported) {
      throw UnsupportedError('Apple Core ML is only available on iOS physical devices and simulators.');
    }

    if (!_isModelLoaded) {
      throw StateError('Core ML model is not loaded. Call initialize() first.');
    }

    try {
      final response = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'predictFrame',
        {
          'imageBytes': frameBytes,
          'width': width,
          'height': height,
        },
      );

      if (response == null || response['success'] != true) {
        throw Exception(response?['message'] ?? 'Core ML prediction failed');
      }

      final classId = response['classId'] as String? ?? '';
      final confidence = (response['confidence'] as num?)?.toDouble() ?? 0.0;
      final inferenceTimeMs = (response['inferenceTimeMs'] as num?)?.toDouble() ?? 0.0;
      final engine = response['engine'] as String? ?? 'Core ML — Automatic';
      _hardwareEngine = engine;

      final names = _resolvePlantNames(classId);

      return RecognitionResult(
        success: true,
        classId: classId,
        nameVi: names.nameVi,
        scientificName: names.scientificName,
        confidence: confidence,
        modelId: _activeModelId,
        modelName: 'Flower Recognition V4 (Core ML)',
        inferenceTimeMs: inferenceTimeMs,
        isFromApi: false, // On-device native AI!
        timestamp: DateTime.now(),
      );
    } on PlatformException catch (e) {
      throw Exception('Core ML runtime error: ${e.message}');
    }
  }

  /// Queries real iOS thermal state: nominal, fair, serious, critical
  Future<String> getThermalState() async {
    if (!isSupported) return 'nominal';
    try {
      final state = await _channel.invokeMethod<String>('getThermalState');
      return state ?? 'nominal';
    } catch (_) {
      return 'nominal';
    }
  }

  /// Disposes model and releases native resources
  Future<void> dispose() async {
    if (isSupported && _isModelLoaded) {
      try {
        await _channel.invokeMethod('disposeModel');
      } catch (_) {}
    }
    _isModelLoaded = false;
  }

  /// Resolves Vietnamese and scientific name for recognized classId
  ({String nameVi, String scientificName}) _resolvePlantNames(String classId) {
    // V4 20 flower classes official dictionary
    const names = {
      'Anemone_coronaria': ('Hoa Hải Quỳ', 'Anemone coronaria'),
      'Antirrhinum_majus': ('Hoa Mõm Sói', 'Antirrhinum majus'),
      'Bellis_perennis': ('Hoa Cúc Anh', 'Bellis perennis'),
      'Celosia_argentea': ('Hoa Mào Gà', 'Celosia argentea'),
      'Chrysanthemum_zawadzkii': ('Hoa Cúc', 'Chrysanthemum zawadzkii'),
      'Crocus_vernus': ('Hoa Crocus', 'Crocus vernus'),
      'Dahlia_coccinea': ('Hoa Thược Dược', 'Dahlia coccinea'),
      'Dianthus_chinensis': ('Hoa Cẩm Chướng', 'Dianthus chinensis'),
      'Echinacea_purpurea': ('Hoa Echinacea', 'Echinacea purpurea'),
      'Fuchsia_magellanica': ('Hoa Fuchsia', 'Fuchsia magellanica'),
      'Gardenia_jasminoides': ('Hoa Dành Dành', 'Gardenia jasminoides'),
      'Helianthus_annuus': ('Hoa Hướng Dương', 'Helianthus annuus'),
      'Hibiscus_syriacus': ('Hoa Dâm Bụt', 'Hibiscus syriacus'),
      'Hydrangea_macrophylla': ('Hoa Cẩm Tú Cầu', 'Hydrangea macrophylla'),
      'Impatiens_walleriana': ('Hoa Ngọc Thảo', 'Impatiens walleriana'),
      'Ipomoea_purpurea': ('Hoa Bìm Bìm', 'Ipomoea purpurea'),
      'Iris_sibirica': ('Hoa Diên Vĩ', 'Iris sibirica'),
      'Ixora_coccinea': ('Hoa Trang', 'Ixora coccinea'),
      'Lavandula_stoechas': ('Hoa Oải Hương', 'Lavandula stoechas'),
      'Nelumbo_nucifera': ('Hoa Sen', 'Nelumbo nucifera'),
    };

    if (names.containsKey(classId)) {
      final pair = names[classId]!;
      return (nameVi: pair.$1, scientificName: pair.$2);
    }

    final formatted = classId.replaceAll('_', ' ');
    return (nameVi: formatted, scientificName: formatted);
  }
}
