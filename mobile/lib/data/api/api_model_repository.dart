import 'package:flutter/foundation.dart';
import '../../core/config/api_config.dart';
import '../../domain/entities/ai_model.dart';
import '../../domain/repositories/model_repository.dart';
import '../mock/mock_model_repository.dart';
import 'api_client.dart';

/// Model repository that communicates with the ASP.NET Core /api/Model endpoints.
/// Seamlessly falls back to MockModelRepository if the backend is unreachable.
class ApiModelRepository implements ModelRepository {
  final ApiClient _apiClient;
  final ModelRepository _fallbackRepository;

  ApiModelRepository({
    required ApiClient apiClient,
    ModelRepository? fallbackRepository,
  })  : _apiClient = apiClient,
        _fallbackRepository = fallbackRepository ?? MockModelRepository();

  @override
  Future<List<AIModel>> getModels() async {
    try {
      final response = await _apiClient.get(ApiConfig.modelsEndpoint);
      if (response.statusCode == 200 && response.data is List) {
        final list = (response.data as List)
            .map((item) => _mapJsonToModel(item as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          return list;
        }
      }
    } catch (e) {
      debugPrint('[ApiModelRepository] Backend unavailable ($e), using fallback models.');
    }
    return _fallbackRepository.getModels();
  }

  @override
  Future<List<AIModel>> getModelsByCategory(String categoryId) async {
    try {
      final allModels = await getModels();
      // Current models in backend (v2, v4) are trained for flowers
      if (categoryId == 'flowers') {
        return allModels;
      }
      return allModels.where((m) => m.categoryIds.contains(categoryId)).toList();
    } catch (_) {
      return _fallbackRepository.getModelsByCategory(categoryId);
    }
  }

  @override
  Future<AIModel?> getModelById(String id) async {
    try {
      final response = await _apiClient.get(ApiConfig.modelDetailEndpoint(id));
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return _mapJsonToModel(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[ApiModelRepository] Failed to fetch model $id ($e), using fallback.');
    }
    return _fallbackRepository.getModelById(id);
  }

  @override
  Future<AIModel?> getDefaultModel(String categoryId) async {
    try {
      final models = await getModelsByCategory(categoryId);
      if (models.isNotEmpty) {
        return models.firstWhere((m) => m.isDefault, orElse: () => models.first);
      }
    } catch (_) {}
    return _fallbackRepository.getDefaultModel(categoryId);
  }

  AIModel _mapJsonToModel(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final statusStr = json['status'] as String? ?? 'Ready';
    final isReady = statusStr.toLowerCase() == 'ready';

    return AIModel(
      id: id,
      displayName: json['displayName'] as String? ?? 'Model $id',
      architecture: json['architecture'] as String? ?? 'CNN',
      version: json['version'] as String? ?? '1.0',
      inputSize: (json['imageSize'] as num?)?.toInt() ?? 224,
      classCount: (json['classCount'] as num?)?.toInt() ?? 20,
      isDefault: id.toLowerCase() == 'v4',
      status: isReady ? ModelStatus.ready : ModelStatus.comingSoon,
      categoryIds: const ['flowers'],
    );
  }
}
