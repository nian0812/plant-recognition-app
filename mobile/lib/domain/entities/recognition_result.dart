/// Result of an AI recognition, compatible with backend PredictionResponse
class RecognitionResult {
  final bool success;
  final String classId;
  final String nameVi;
  final String? nameEn;
  final String? scientificName;
  final double confidence;
  final String modelId;
  final String modelName;
  final double? inferenceTimeMs;
  final List<PredictionDetail>? topPredictions;
  final DateTime timestamp;
  final String? imagePath;
  final bool isFromApi;
  final String? rawResponse;

  const RecognitionResult({
    required this.success,
    required this.classId,
    required this.nameVi,
    this.nameEn,
    this.scientificName,
    required this.confidence,
    required this.modelId,
    required this.modelName,
    this.inferenceTimeMs,
    this.topPredictions,
    required this.timestamp,
    this.imagePath,
    this.isFromApi = false,
    this.rawResponse,
  });

  int get numericClassId => int.tryParse(classId) ?? 0;

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(2)}%';

  factory RecognitionResult.fromBackendJson(
    Map<String, dynamic> json, {
    String? imagePath,
    double? inferenceTimeMs,
    String? rawResponse,
  }) {
    return RecognitionResult(
      success: json['success'] as bool? ?? true,
      classId: json['classId']?.toString() ?? '',
      nameVi: json['nameVi'] as String? ?? 'Chưa xác định',
      nameEn: json['nameEn'] as String?,
      scientificName: json['scientificName'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      modelId: json['modelId'] as String? ?? '',
      modelName: json['modelName'] as String? ?? '',
      inferenceTimeMs: inferenceTimeMs,
      timestamp: DateTime.now(),
      imagePath: imagePath,
      isFromApi: true,
      rawResponse: rawResponse,
    );
  }

  RecognitionResult copyWith({
    bool? success,
    String? classId,
    String? nameVi,
    String? nameEn,
    String? scientificName,
    double? confidence,
    String? modelId,
    String? modelName,
    List<PredictionDetail>? topPredictions,
    double? inferenceTimeMs,
    DateTime? timestamp,
    String? imagePath,
    bool? isFromApi,
    String? rawResponse,
  }) {
    return RecognitionResult(
      success: success ?? this.success,
      classId: classId ?? this.classId,
      nameVi: nameVi ?? this.nameVi,
      nameEn: nameEn ?? this.nameEn,
      scientificName: scientificName ?? this.scientificName,
      confidence: confidence ?? this.confidence,
      modelId: modelId ?? this.modelId,
      modelName: modelName ?? this.modelName,
      topPredictions: topPredictions ?? this.topPredictions,
      inferenceTimeMs: inferenceTimeMs ?? this.inferenceTimeMs,
      timestamp: timestamp ?? this.timestamp,
      imagePath: imagePath ?? this.imagePath,
      isFromApi: isFromApi ?? this.isFromApi,
      rawResponse: rawResponse ?? this.rawResponse,
    );
  }
}

class PredictionDetail {
  final String classId;
  final String nameVi;
  final String? nameEn;
  final String? scientificName;
  final double confidence;

  const PredictionDetail({
    required this.classId,
    required this.nameVi,
    this.nameEn,
    this.scientificName,
    required this.confidence,
  });

  int get numericClassId => int.tryParse(classId) ?? 0;

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(2)}%';
}
