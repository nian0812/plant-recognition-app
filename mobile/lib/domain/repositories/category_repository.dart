import '../entities/recognition_category.dart';

abstract class CategoryRepository {
  Future<List<RecognitionCategory>> getCategories();
  Future<RecognitionCategory?> getCategoryById(String id);
}
