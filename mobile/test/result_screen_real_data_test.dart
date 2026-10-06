import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_recognition/domain/entities/recognition_result.dart';
import 'package:plant_recognition/presentation/screens/result/result_screen.dart';

void main() {
  testWidgets('ResultScreen correctly displays Real AI Result & Badges', (tester) async {
    // Create actual RecognitionResult as returned by backend ONNX V4
    final realResult = RecognitionResult(
      success: true,
      classId: 'Helianthus_annuus',
      nameVi: 'Hoa hướng dương',
      scientificName: 'Helianthus annuus',
      confidence: 0.8729,
      modelId: 'v4',
      modelName: 'Flower Recognition V4',
      isFromApi: true,
      inferenceTimeMs: 145.2,
      timestamp: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ResultScreen(
          extra: {
            'result': realResult,
            'imagePath': r'D:\plant-recognition-app\images\hhd.webp',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Plant Name
    expect(find.text('Hoa hướng dương'), findsOneWidget);

    // 2. Verify Scientific Name
    expect(find.text('Helianthus annuus'), findsOneWidget);

    // 3. Verify Confidence
    expect(find.text('87.29%'), findsOneWidget);

    // 4. Verify Model Name
    expect(find.text('Mô hình: Flower Recognition V4'), findsOneWidget);

    // 5. Verify Latency Display
    expect(find.text('145.2 ms'), findsOneWidget);

    // 6. Verify REAL API BADGES
    expect(find.text('🌐 API Thật'), findsOneWidget);
    expect(find.text('● ASP.NET Core AI'), findsOneWidget);

    // 7. Verify Mock Fallback is NOT displayed!
    expect(find.text('⚡ Mock Fallback'), findsNothing);
    expect(find.text('● On-Device AI (Mock)'), findsNothing);
  });
}
