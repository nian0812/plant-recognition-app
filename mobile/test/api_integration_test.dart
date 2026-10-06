import 'package:flutter_test/flutter_test.dart';
import 'package:plant_recognition/core/config/api_config.dart';
import 'package:plant_recognition/data/api/api_client.dart';
import 'package:plant_recognition/data/api/api_model_repository.dart';
import 'package:plant_recognition/data/api/api_recognition_repository.dart';
import 'package:plant_recognition/domain/entities/recognition_result.dart';

void main() {
  group('ApiConfig Tests', () {
    test('Default base URL is resolved and endpoints are formatted properly', () {
      final defaultUrl = ApiConfig.defaultBaseUrl;
      expect(defaultUrl, isNotEmpty);
      expect(defaultUrl, contains('5217'));

      expect(ApiConfig.modelsEndpoint, '/api/Model');
      expect(ApiConfig.modelDetailEndpoint('v4'), '/api/Model/v4');
      expect(ApiConfig.modelClassesEndpoint('v2'), '/api/Model/v2/classes');
      expect(ApiConfig.predictEndpoint('v4'), '/api/Recognition/predict?modelId=v4');
    });
  });

  group('RecognitionResult Backend DTO Parsing Tests', () {
    test('Correctly parses backend ASP.NET Core PredictionResult JSON response', () {
      final backendJson = {
        'success': true,
        'classId': 'Helianthus_annuus',
        'nameVi': 'Hoa Hướng Dương',
        'scientificName': 'Helianthus annuus',
        'confidence': 0.9421,
        'modelId': 'v4',
        'modelName': 'Flower Recognition V4',
      };

      final result = RecognitionResult.fromBackendJson(
        backendJson,
        imagePath: '/path/to/sunflower.jpg',
        inferenceTimeMs: 45.2,
      );

      expect(result.success, isTrue);
      expect(result.classId, 'Helianthus_annuus');
      expect(result.nameVi, 'Hoa Hướng Dương');
      expect(result.scientificName, 'Helianthus annuus');
      expect(result.confidence, 0.9421);
      expect(result.confidencePercent, '94.21%');
      expect(result.modelId, 'v4');
      expect(result.modelName, 'Flower Recognition V4');
      expect(result.isFromApi, isTrue);
      expect(result.inferenceTimeMs, 45.2);
    });

    test('Correctly parses v2 model prediction JSON response', () {
      final backendJson = {
        'success': true,
        'classId': 'Rosa',
        'nameVi': 'Hoa Hồng',
        'scientificName': 'Rosa',
        'confidence': 0.8875,
        'modelId': 'v2',
        'modelName': 'Flower Recognition V2',
      };

      final result = RecognitionResult.fromBackendJson(backendJson);

      expect(result.success, isTrue);
      expect(result.classId, 'Rosa');
      expect(result.nameVi, 'Hoa Hồng');
      expect(result.confidencePercent, '88.75%');
      expect(result.modelId, 'v2');
      expect(result.isFromApi, isTrue);
    });
  });

  group('ApiModelRepository & ApiRecognitionRepository Fallback Tests', () {
    test('ApiModelRepository gracefully returns models even when backend is offline', () async {
      final apiClient = ApiClient(baseUrl: 'http://127.0.0.1:59999'); // dummy offline port
      final repository = ApiModelRepository(apiClient: apiClient);

      final models = await repository.getModels();
      expect(models, isNotEmpty);
      expect(models.any((m) => m.id == 'v4'), isTrue);
      expect(models.any((m) => m.id == 'v2'), isTrue);
    });

    test('ApiRecognitionRepository falls back to Mock without throwing when offline', () async {
      final apiClient = ApiClient(baseUrl: 'http://127.0.0.1:59999');
      final repository = ApiRecognitionRepository(
        apiClient: apiClient,
        enableFallback: true,
      );

      final result = await repository.recognizeImage(
        modelId: 'v4',
        categoryId: 'flowers',
      );

      expect(result.success, isTrue);
      expect(result.nameVi, isNotEmpty);
      expect(result.confidence, greaterThan(0));
    });
  });
}
