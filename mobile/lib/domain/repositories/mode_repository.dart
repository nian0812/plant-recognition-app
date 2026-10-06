import '../entities/recognition_mode.dart';

abstract class ModeRepository {
  Future<List<RecognitionMode>> getModes();
  Future<List<RecognitionMode>> getModesForCategory(String categoryId);
}
