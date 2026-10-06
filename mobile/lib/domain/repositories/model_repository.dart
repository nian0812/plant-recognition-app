import '../entities/ai_model.dart';

abstract class ModelRepository {
  Future<List<AIModel>> getModels();
  Future<List<AIModel>> getModelsByCategory(String categoryId);
  Future<AIModel?> getModelById(String id);
  Future<AIModel?> getDefaultModel(String categoryId);
}
