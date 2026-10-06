import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:plant_recognition/main.dart';
import 'package:plant_recognition/core/router/app_router.dart';
import 'package:plant_recognition/presentation/screens/home/home_screen.dart';
import 'package:plant_recognition/presentation/screens/category/category_screen.dart';
import 'package:plant_recognition/presentation/screens/mode_select/mode_select_screen.dart';
import 'package:plant_recognition/presentation/screens/model_select/model_select_screen.dart';
import 'package:plant_recognition/presentation/screens/image_source/image_source_screen.dart';
import 'package:plant_recognition/presentation/screens/camera_live/camera_live_screen.dart';
import 'package:plant_recognition/presentation/screens/result/result_screen.dart';
import 'package:plant_recognition/presentation/screens/biological_profile/biological_profile_screen.dart';
import 'package:plant_recognition/presentation/screens/history/history_screen.dart';
import 'package:plant_recognition/presentation/screens/settings/settings_screen.dart';
import 'package:plant_recognition/presentation/screens/settings/performance_settings_screen.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> flushTimers(WidgetTester tester, {int count = 4}) async {
    for (int i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 600));
    }
  }

  testWidgets('Smoke Test: 12 Screens and Complete App Navigation Flow',
      (WidgetTester tester) async {
    // 1. Mount App with ProviderScope & GoRouter
    await tester.pumpWidget(
      const ProviderScope(
        child: PlantRecognitionApp(),
      ),
    );
    await flushTimers(tester);

    // SCREEN 1: Home / Hub
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Nhận dạng thực vật'), findsOneWidget);
    expect(find.text('Bạn muốn nhận dạng gì?'), findsOneWidget);
    expect(find.text('Hoa'), findsOneWidget);

    // SCREEN 2: Category Screen
    appRouter.go('/category/flowers');
    await flushTimers(tester);
    expect(find.byType(CategoryScreen), findsOneWidget);
    expect(find.text('Giới thiệu'), findsOneWidget);
    expect(find.text('Chế độ nhận dạng'), findsOneWidget);

    // SCREEN 3: Recognition Mode Select Screen
    appRouter.go('/category/flowers/mode');
    await flushTimers(tester);
    expect(find.byType(ModeSelectScreen), findsOneWidget);
    expect(find.text('Chọn cách thức AI xử lý hình ảnh:'), findsOneWidget);
    expect(find.textContaining('Ảnh đơn'), findsOneWidget);
    expect(find.textContaining('Nhận dạng trực tiếp'), findsOneWidget);

    // SCREEN 4: AI Model Select Screen
    appRouter.go('/category/flowers/mode/single_image/model');
    await flushTimers(tester);
    expect(find.byType(ModelSelectScreen), findsOneWidget);
    expect(find.text('Chọn mô hình AI'), findsOneWidget);
    expect(find.text('Flower Recognition V4'), findsOneWidget);

    // SCREEN 5: Image Source Select Screen
    appRouter.go('/category/flowers/mode/single_image/model/v4/source');
    await flushTimers(tester);
    expect(find.byType(ImageSourceScreen), findsOneWidget);
    expect(find.text('Chọn nguồn ảnh'), findsOneWidget);
    expect(find.text('Chụp ảnh từ Camera'), findsOneWidget);
    expect(find.text('Chọn từ Thư viện'), findsOneWidget);

    // SCREEN 6: Camera Live Screen
    appRouter.go('/camera-live', extra: {'categoryId': 'flowers', 'modelId': 'v4'});
    await flushTimers(tester);
    expect(find.byType(CameraLiveScreen), findsOneWidget);
    expect(find.textContaining('AI On-Device'), findsOneWidget);
    expect(find.text('Helianthus annuus'), findsOneWidget);

    // SCREEN 7 & 8: Processing to Result Transition
    appRouter.go('/processing', extra: {
      'imagePath': '',
      'modelId': 'v4',
      'categoryId': 'flowers',
    });
    // Flush timers to complete AI simulation and arrive at ResultScreen
    await flushTimers(tester, count: 6);

    // SCREEN 8: Result Screen
    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.text('Kết quả phân tích'), findsOneWidget);
    expect(find.text('Hoa Hướng Dương'), findsOneWidget);
    expect(find.text('94.21%'), findsOneWidget);
    expect(find.text('📖  Xem hồ sơ sinh học >'), findsOneWidget);

    // SCREEN 9: Biological Profile Screen
    appRouter.go('/biological-profile/0');
    await flushTimers(tester);
    expect(find.byType(BiologicalProfileScreen), findsOneWidget);
    expect(find.text('Hồ sơ sinh học'), findsOneWidget);
    expect(find.text('Hoa Hướng Dương'), findsOneWidget);
    expect(find.text('Họ (Family)'), findsOneWidget);

    // SCREEN 10: History Screen
    appRouter.go('/history');
    await flushTimers(tester);
    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(find.text('Lịch sử nhận dạng'), findsOneWidget);

    // SCREEN 11: Settings Screen
    appRouter.go('/settings');
    await flushTimers(tester);
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Cài đặt'), findsOneWidget);
    expect(find.text('Giao diện & Trải nghiệm'), findsOneWidget);
    expect(find.text('Ngôn ngữ'), findsOneWidget);

    // SCREEN 12: Performance & Hardware Settings Screen
    appRouter.go('/settings/performance');
    await flushTimers(tester);
    expect(find.byType(PerformanceSettingsScreen), findsOneWidget);
    expect(find.text('Hiệu suất & Phần cứng'), findsOneWidget);
    expect(find.text('AI Engine Hardware Status'), findsOneWidget);
    expect(find.text('Hiệu năng tổng thể'), findsOneWidget);

    // Return to Home Screen
    appRouter.go('/');
    await flushTimers(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Smoke Test: Back navigation and button action flows',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PlantRecognitionApp(),
      ),
    );
    await flushTimers(tester);

    // 1. Navigate to Category and test back button
    appRouter.go('/category/flowers');
    await flushTimers(tester);
    expect(find.byType(CategoryScreen), findsOneWidget);

    final backButton = find.byIcon(Icons.arrow_back);
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await flushTimers(tester);
    expect(find.byType(HomeScreen), findsOneWidget);

    // 2. Result Screen -> Tap 'Xem hồ sơ sinh học'
    appRouter.go('/result');
    await flushTimers(tester);
    expect(find.byType(ResultScreen), findsOneWidget);

    final viewProfileButton = find.text('📖  Xem hồ sơ sinh học >');
    expect(viewProfileButton, findsOneWidget);
    await tester.ensureVisible(viewProfileButton);
    await tester.tap(viewProfileButton);
    await flushTimers(tester);
    expect(find.byType(BiologicalProfileScreen), findsOneWidget);

    // 3. Performance Settings -> Toggle Adaptive Performance
    appRouter.go('/settings/performance');
    await flushTimers(tester);
    expect(find.byType(PerformanceSettingsScreen), findsOneWidget);

    final switchWidget = find.byType(Switch);
    expect(switchWidget, findsWidgets);
    await tester.tap(switchWidget.first);
    await flushTimers(tester);
    expect(find.byType(PerformanceSettingsScreen), findsOneWidget);
  });
}
