import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/live_recognition_provider.dart';
import 'widgets/live_overlay_widget.dart';
import 'widgets/performance_overlay_widget.dart';

class CameraLiveScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final String modelId;

  const CameraLiveScreen({
    super.key,
    required this.categoryId,
    required this.modelId,
  });

  @override
  ConsumerState<CameraLiveScreen> createState() => _CameraLiveScreenState();
}

class _CameraLiveScreenState extends ConsumerState<CameraLiveScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Start session once widget tree is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(liveRecognitionProvider.notifier).startSession(
            modelId: widget.modelId.isNotEmpty ? widget.modelId : 'v4',
          );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(liveRecognitionProvider.notifier);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      notifier.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      notifier.onAppResumed();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveState = ref.watch(liveRecognitionProvider);
    final notifier = ref.read(liveRecognitionProvider.notifier);
    final performanceSettings = ref.watch(performanceSettingsProvider);
    final controller = notifier.cameraController;

    final effectiveModelName =
        widget.modelId.toLowerCase().contains('v2') ? 'V2' : 'V4';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Viewfinder or Preview
          if (controller != null &&
              controller.value.isInitialized &&
              liveState.isCameraActive)
            Center(
              child: CameraPreview(controller),
            )
          else
            _buildViewfinderPlaceholder(liveState),

          // 2. Safe Area UI Overlay
          SafeArea(
            child: Column(
              children: [
                // Top App Bar
                _buildTopBar(context, effectiveModelName, liveState),

                // Technical Performance HUD Overlay (if enabled)
                if (performanceSettings.showPerformanceOverlay)
                  PerformanceOverlayWidget(
                    cameraFps: liveState.cameraFps,
                    aiFps: liveState.aiFps,
                    latencyMs: liveState.latencyMs,
                    engine: liveState.hardwareEngine,
                    thermalState: liveState.thermalState,
                    modelName: '$effectiveModelName (Core ML)',
                  ),

                const Spacer(),

                // Live Botanical Recognition Card Overlay
                LiveOverlayWidget(
                  result: liveState.smoothedResult,
                  isModelLoaded: liveState.isModelLoaded,
                ),

                // Bottom Control Toolbar
                _buildControlToolbar(context, notifier, liveState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(
      BuildContext context, String modelName, LiveRecognitionState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => context.safePop(),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: state.isModelLoaded ? AppColors.accent : AppColors.amber,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  state.isModelLoaded
                      ? 'AI On-Device: $modelName (Sẵn sàng)'
                      : 'AI On-Device: Đang tải $modelName...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.speed, color: Colors.white, size: 26),
            onPressed: () => context.push('/settings/performance'),
          ),
        ],
      ),
    );
  }

  Widget _buildControlToolbar(
    BuildContext context,
    LiveRecognitionNotifier notifier,
    LiveRecognitionState state,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Flash toggle
          IconButton(
            icon: Icon(
              state.isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: state.isFlashOn ? Colors.amberAccent : Colors.white70,
              size: 28,
            ),
            onPressed: () => notifier.toggleFlash(),
          ),

          // Main Shutter Button / Snapshot
          GestureDetector(
            onTap: () {
              if (state.smoothedResult != null) {
                context.push('/biological-profile/${state.smoothedResult!.classId}');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đang quét cây... Vui lòng giữ chắc camera.'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                color: AppColors.primary.withValues(alpha: 0.8),
              ),
              child: const Center(
                child: Icon(Icons.center_focus_strong, color: Colors.white, size: 34),
              ),
            ),
          ),

          // Flip camera
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white70, size: 28),
            onPressed: () => notifier.switchCamera(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinderPlaceholder(LiveRecognitionState state) {
    return Container(
      color: AppColors.darkBackground,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.darkSurface,
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.camera_alt_outlined, color: AppColors.accent, size: 40),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Live On-Device Camera Viewfinder',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                state.errorMessage ??
                    'Frame Scheduler & Core ML V4 đã sẵn sàng.\n(Camera vật lý tự động kích hoạt trên iPhone)',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
