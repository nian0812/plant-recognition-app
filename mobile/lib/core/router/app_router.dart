import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/category/category_screen.dart';
import '../../presentation/screens/mode_select/mode_select_screen.dart';
import '../../presentation/screens/model_select/model_select_screen.dart';
import '../../presentation/screens/image_source/image_source_screen.dart';
import '../../presentation/screens/camera_live/camera_live_screen.dart';
import '../../presentation/screens/processing/processing_screen.dart';
import '../../presentation/screens/result/result_screen.dart';
import '../../presentation/screens/biological_profile/biological_profile_screen.dart';
import '../../presentation/screens/history/history_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/settings/performance_settings_screen.dart';

/// App route paths.
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String category = '/category/:categoryId';
  static const String modeSelect = '/category/:categoryId/mode';
  static const String modelSelect = '/category/:categoryId/mode/:modeId/model';
  static const String imageSource =
      '/category/:categoryId/mode/:modeId/model/:modelId/source';
  static const String cameraLive = '/camera-live';
  static const String processing = '/processing';
  static const String result = '/result';
  static const String biologicalProfile = '/biological-profile/:classId';
  static const String history = '/history';
  static const String settings = '/settings';
  static const String performanceSettings = '/settings/performance';
}

/// Central app router configuration.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.category,
      builder: (context, state) {
        final categoryId = state.pathParameters['categoryId']!;
        return CategoryScreen(categoryId: categoryId);
      },
    ),
    GoRoute(
      path: AppRoutes.modeSelect,
      builder: (context, state) {
        final categoryId = state.pathParameters['categoryId']!;
        return ModeSelectScreen(categoryId: categoryId);
      },
    ),
    GoRoute(
      path: AppRoutes.modelSelect,
      builder: (context, state) {
        final categoryId = state.pathParameters['categoryId']!;
        final modeId = state.pathParameters['modeId']!;
        return ModelSelectScreen(categoryId: categoryId, modeId: modeId);
      },
    ),
    GoRoute(
      path: AppRoutes.imageSource,
      builder: (context, state) {
        final categoryId = state.pathParameters['categoryId']!;
        final modeId = state.pathParameters['modeId']!;
        final modelId = state.pathParameters['modelId']!;
        return ImageSourceScreen(
          categoryId: categoryId,
          modeId: modeId,
          modelId: modelId,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.cameraLive,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return CameraLiveScreen(
          categoryId: extra['categoryId'] as String? ?? '',
          modelId: extra['modelId'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.processing,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ProcessingScreen(
          imagePath: extra['imagePath'] as String? ?? '',
          modelId: extra['modelId'] as String? ?? '',
          categoryId: extra['categoryId'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.result,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ResultScreen(extra: extra);
      },
    ),
    GoRoute(
      path: AppRoutes.biologicalProfile,
      builder: (context, state) {
        final classId =
            int.tryParse(state.pathParameters['classId'] ?? '0') ?? 0;
        return BiologicalProfileScreen(classId: classId);
      },
    ),
    GoRoute(
      path: AppRoutes.history,
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.performanceSettings,
      builder: (context, state) => const PerformanceSettingsScreen(),
    ),
  ],
);

/// Safe navigation extension to prevent "There is nothing to pop" GoError.
extension SafeNavContext on BuildContext {
  void safePop({String fallbackLocation = '/'}) {
    if (canPop()) {
      pop();
    } else {
      go(fallbackLocation);
    }
  }
}

