import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_recognition/data/api/api_client.dart';
import 'package:plant_recognition/data/api/api_model_repository.dart';
import 'package:plant_recognition/data/api/api_recognition_repository.dart';

void main() {
  group('Phase 2.5 Real End-To-End AI Test with ASP.NET Core & ONNX V4', () {
    const String baseUrl = 'http://localhost:5217';
    late ApiClient apiClient;
    late ApiModelRepository modelRepo;
    late ApiRecognitionRepository recognitionRepo;

    setUp(() {
      apiClient = ApiClient(baseUrl: baseUrl);
      modelRepo = ApiModelRepository(apiClient: apiClient);
      recognitionRepo = ApiRecognitionRepository(
        apiClient: apiClient,
        enableFallback: false, // Strict: Fail if API fails, do NOT silently mock!
      );
    });

    test('Step 1: Verify ASP.NET Core Backend is running and reachable', () async {
      final isReachable = await apiClient.isBackendReachable();
      expect(
        isReachable,
        isTrue,
        reason: 'Backend ASP.NET Core must be running at http://localhost:5217',
      );
    });

    test('Step 2: GET /api/Model returns real ONNX V4 model', () async {
      final models = await modelRepo.getModels();
      expect(models.isNotEmpty, isTrue);

      final modelV4 = models.firstWhere((m) => m.id == 'v4');
      expect(modelV4.id, equals('v4'));
      expect(modelV4.displayName, contains('V4'));
      expect(modelV4.classCount, equals(20));
    });

    test('Step 3: End-to-end Real Recognition with hhd.webp using ONNX V4', () async {
      final imageFile = io.File(r'D:\plant-recognition-app\images\hhd.webp');
      expect(
        imageFile.existsSync(),
        isTrue,
        reason: 'Test image hhd.webp must exist',
      );

      final imageBytes = await imageFile.readAsBytes();

      // Send real POST /api/Recognition/predict?modelId=v4
      final result = await recognitionRepo.recognizeImage(
        imageBytes: imageBytes,
        imagePath: imageFile.path,
        modelId: 'v4',
      );

      // Verify real ONNX response
      expect(result.success, isTrue);
      expect(result.isFromApi, isTrue, reason: 'Must be from real API, not Mock!');
      expect(result.classId, equals('Helianthus_annuus'));
      expect(result.nameVi, equals('Hoa hướng dương'));
      expect(result.scientificName, equals('Helianthus annuus'));
      expect(result.confidence, greaterThan(0.80)); // Expected ~87.29%
      expect(result.modelId, equals('v4'));
      expect(result.modelName, equals('Flower Recognition V4'));
      expect(result.inferenceTimeMs, isNotNull);
      expect(result.inferenceTimeMs!, greaterThan(0));

      debugPrint('==================================================');
      debugPrint('[E2E TEST 1 SUCCESS] Image: hhd.webp');
      debugPrint('Predicted Name (VI): ${result.nameVi}');
      debugPrint('Scientific Name: ${result.scientificName}');
      debugPrint('Confidence: ${result.confidencePercent}');
      debugPrint('Latency: ${result.inferenceTimeMs} ms');
      debugPrint('Model: ${result.modelName} (ID: ${result.modelId})');
      debugPrint('isFromApi: ${result.isFromApi}');
      debugPrint('==================================================');
    });

    test('Step 4: End-to-end Real Recognition with hoasen.jpg using ONNX V4', () async {
      final imageFile = io.File(r'D:\plant-recognition-app\images\hoasen.jpg');
      expect(imageFile.existsSync(), isTrue);

      final imageBytes = await imageFile.readAsBytes();

      final result = await recognitionRepo.recognizeImage(
        imageBytes: imageBytes,
        imagePath: imageFile.path,
        modelId: 'v4',
      );

      expect(result.success, isTrue);
      expect(result.isFromApi, isTrue);
      expect(result.classId, equals('Nelumbo_nucifera'));
      expect(result.nameVi, equals('Hoa sen'));
      expect(result.scientificName, equals('Nelumbo nucifera'));
      expect(result.confidence, greaterThan(0.85)); // Expected ~90.38%
      expect(result.modelId, equals('v4'));

      debugPrint('==================================================');
      debugPrint('[E2E TEST 2 SUCCESS] Image: hoasen.jpg');
      debugPrint('Predicted Name (VI): ${result.nameVi}');
      debugPrint('Confidence: ${result.confidencePercent}');
      debugPrint('Latency: ${result.inferenceTimeMs} ms');
      debugPrint('==================================================');
    });
  });
}
