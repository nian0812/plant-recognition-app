import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/model_repository.dart';
import '../../domain/repositories/recognition_repository.dart';
import '../../domain/repositories/plant_profile_repository.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/entities/recognition_category.dart';
import '../../domain/entities/ai_model.dart';
import '../../domain/entities/recognition_mode.dart';
import '../../domain/entities/performance_settings.dart';
import '../../domain/entities/recognition_history_item.dart';
import '../../domain/entities/recognition_result.dart';
import '../../data/mock/mock_category_repository.dart';
import '../../data/mock/mock_model_repository.dart';
import '../../data/mock/mock_recognition_repository.dart';
import '../../data/mock/mock_plant_profile_repository.dart';
import '../../data/mock/mock_history_repository.dart';
import '../../data/mock/mock_mode_repository.dart';
import '../../domain/repositories/mode_repository.dart';
import '../config/api_config.dart';
import '../../data/api/api_client.dart';
import '../../data/api/api_model_repository.dart';
import '../../data/api/api_recognition_repository.dart';

// ============================================================
// API & Network Configuration Providers
// ============================================================

final apiBaseUrlProvider = StateProvider<String>((ref) {
  return ApiConfig.defaultBaseUrl;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return ApiClient(baseUrl: baseUrl);
});

final useApiProvider = StateProvider<bool>((ref) => true);

// ============================================================
// Repository Providers
// ============================================================

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return MockCategoryRepository();
});

final modeRepositoryProvider = Provider<ModeRepository>((ref) {
  return MockModeRepository();
});

final modelRepositoryProvider = Provider<ModelRepository>((ref) {
  final useApi = ref.watch(useApiProvider);
  if (!useApi) {
    return MockModelRepository();
  }
  final apiClient = ref.watch(apiClientProvider);
  return ApiModelRepository(
    apiClient: apiClient,
    fallbackRepository: MockModelRepository(),
  );
});

final recognitionRepositoryProvider = Provider<RecognitionRepository>((ref) {
  final useApi = ref.watch(useApiProvider);
  if (!useApi) {
    return MockRecognitionRepository();
  }
  final apiClient = ref.watch(apiClientProvider);
  return ApiRecognitionRepository(
    apiClient: apiClient,
    fallbackRepository: MockRecognitionRepository(),
    enableFallback: true,
  );
});

final plantProfileRepositoryProvider = Provider<PlantProfileRepository>((ref) {
  return MockPlantProfileRepository();
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return MockHistoryRepository();
});

// ============================================================
// Data Providers
// ============================================================

final categoriesProvider = FutureProvider<List<RecognitionCategory>>((ref) {
  return ref.watch(categoryRepositoryProvider).getCategories();
});

final categoryProvider =
    FutureProvider.family<RecognitionCategory?, String>((ref, id) {
  return ref.watch(categoryRepositoryProvider).getCategoryById(id);
});

final modesForCategoryProvider =
    FutureProvider.family<List<RecognitionMode>, String>((ref, categoryId) {
  return ref.watch(modeRepositoryProvider).getModesForCategory(categoryId);
});

final modelsForCategoryProvider =
    FutureProvider.family<List<AIModel>, String>((ref, categoryId) {
  return ref.watch(modelRepositoryProvider).getModelsByCategory(categoryId);
});

final modelProvider = FutureProvider.family<AIModel?, String>((ref, id) {
  return ref.watch(modelRepositoryProvider).getModelById(id);
});

final defaultModelProvider =
    FutureProvider.family<AIModel?, String>((ref, categoryId) {
  return ref.watch(modelRepositoryProvider).getDefaultModel(categoryId);
});

final historyProvider =
    StateNotifierProvider<HistoryNotifier, AsyncValue<List<RecognitionHistoryItem>>>(
        (ref) {
  return HistoryNotifier(ref.watch(historyRepositoryProvider));
});

class HistoryNotifier
    extends StateNotifier<AsyncValue<List<RecognitionHistoryItem>>> {
  final HistoryRepository _repository;

  HistoryNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      final list = await _repository.getHistory();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteHistory(String id) async {
    await _repository.deleteHistoryItem(id);
    await loadHistory();
  }

  Future<void> addResult(RecognitionResult result) async {
    await _repository.addToHistory(result);
    await loadHistory();
  }
}

// ============================================================
// UI State Providers
// ============================================================

final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);
final selectedModeIdProvider = StateProvider<String?>((ref) => null);
final selectedModelIdProvider = StateProvider<String?>((ref) => null);

final performanceSettingsProvider =
    StateNotifierProvider<PerformanceSettingsNotifier, PerformanceSettings>(
        (ref) {
  return PerformanceSettingsNotifier();
});

class PerformanceSettingsNotifier extends StateNotifier<PerformanceSettings> {
  PerformanceSettingsNotifier() : super(const PerformanceSettings());

  void updateSettings(PerformanceSettings newSettings) {
    state = newSettings;
  }

  void updateCameraFps(CameraFpsOption value) {
    state = state.copyWith(cameraFps: value);
  }

  void updateAiInferenceFps(AiInferenceFps value) {
    state = state.copyWith(aiInferenceFps: value);
  }

  void updatePerformanceMode(PerformanceMode value) {
    state = state.copyWith(performanceMode: value);
  }

  void updateCameraResolution(CameraResolution value) {
    state = state.copyWith(cameraResolution: value);
  }

  void toggleAdaptivePerformance() {
    state = state.copyWith(adaptivePerformance: !state.adaptivePerformance);
  }

  void updateAiEngine(AiEngineType value) {
    state = state.copyWith(aiEngine: value);
  }

  void togglePerformanceOverlay() {
    state =
        state.copyWith(showPerformanceOverlay: !state.showPerformanceOverlay);
  }
}
