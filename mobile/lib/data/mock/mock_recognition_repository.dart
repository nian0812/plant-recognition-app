import 'dart:typed_data';
import '../../domain/entities/recognition_result.dart';
import '../../domain/repositories/recognition_repository.dart';

class MockRecognitionRepository implements RecognitionRepository {
  @override
  Future<RecognitionResult> recognizeImage({
    Uint8List? imageBytes,
    String? imagePath,
    required String modelId,
    String? categoryId,
    int topN = 5,
  }) async {
    // Simulate AI inference latency
    await Future.delayed(const Duration(milliseconds: 1500));

    final isV4 = modelId.toLowerCase().contains('v4');

    return RecognitionResult(
      success: true,
      classId: 'Helianthus_annuus',
      nameVi: 'Hoa Hướng Dương',
      nameEn: 'Sunflower',
      scientificName: 'Helianthus annuus',
      confidence: 0.9421,
      modelId: modelId,
      modelName: isV4 ? 'Flower Recognition V4' : 'Flower Recognition V2',
      inferenceTimeMs: isV4 ? 128.5 : 84.2,
      topPredictions: const [
        PredictionDetail(
          classId: 'Helianthus_annuus',
          nameVi: 'Hoa Hướng Dương',
          nameEn: 'Sunflower',
          scientificName: 'Helianthus annuus',
          confidence: 0.9421,
        ),
        PredictionDetail(
          classId: 'Chrysanthemum_morifolium',
          nameVi: 'Hoa Cúc Vàng',
          nameEn: 'Chrysanthemum',
          scientificName: 'Chrysanthemum morifolium',
          confidence: 0.0345,
        ),
        PredictionDetail(
          classId: 'Rosa',
          nameVi: 'Hoa Hồng',
          nameEn: 'Rose',
          scientificName: 'Rosa',
          confidence: 0.0128,
        ),
      ],
      timestamp: DateTime.now(),
      imagePath: imagePath,
      isFromApi: false,
    );
  }
}
