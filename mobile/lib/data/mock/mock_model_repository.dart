import '../../domain/entities/ai_model.dart';
import '../../domain/repositories/model_repository.dart';

class MockModelRepository implements ModelRepository {
  final List<AIModel> _models = const [
    AIModel(
      id: 'v4',
      displayName: 'Flower Recognition V4',
      architecture: 'EfficientNetV2-S',
      version: '4.0',
      inputSize: 384,
      classCount: 20,
      isDefault: true,
      status: ModelStatus.ready,
      categoryIds: ['flowers'],
    ),
    AIModel(
      id: 'v2',
      displayName: 'Flower Recognition V2',
      architecture: 'EfficientNet-B0',
      version: '2.0',
      inputSize: 224,
      classCount: 50,
      isDefault: false,
      status: ModelStatus.ready,
      categoryIds: ['flowers'],
    ),
  ];

  @override
  Future<List<AIModel>> getModels() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _models;
  }

  @override
  Future<List<AIModel>> getModelsByCategory(String categoryId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _models.where((m) => m.categoryIds.contains(categoryId)).toList();
  }

  @override
  Future<AIModel?> getModelById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      return _models.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AIModel?> getDefaultModel(String categoryId) async {
    final list = await getModelsByCategory(categoryId);
    if (list.isEmpty) return null;
    return list.firstWhere((m) => m.isDefault, orElse: () => list.first);
  }
}
