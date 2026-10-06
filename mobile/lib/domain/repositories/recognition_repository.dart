import 'dart:typed_data';
import '../entities/recognition_result.dart';

abstract class RecognitionRepository {
  Future<RecognitionResult> recognizeImage({
    Uint8List? imageBytes,
    String? imagePath,
    required String modelId,
    String? categoryId,
    int topN = 5,
  });
}
