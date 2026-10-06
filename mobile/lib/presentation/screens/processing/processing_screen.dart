import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  final String imagePath;
  final String modelId;
  final String categoryId;

  const ProcessingScreen({
    super.key,
    required this.imagePath,
    required this.modelId,
    required this.categoryId,
  });

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  double _progress = 0.0;
  String _statusMessage = 'Đang chuẩn bị hình ảnh...';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _startMockProgress();
    _processImage();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _startMockProgress() {
    _timer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (!mounted) return;
      setState(() {
        if (_progress < 0.30) {
          _progress += 0.02;
          _statusMessage = 'Đang chuẩn bị hình ảnh...';
        } else if (_progress < 0.65) {
          _progress += 0.025;
          _statusMessage = 'Đang trích xuất đặc trưng...';
        } else if (_progress < 0.92) {
          _progress += 0.02;
          _statusMessage = 'Đang chạy mô hình AI...';
        } else if (_progress < 0.99) {
          _progress += 0.005;
          _statusMessage = 'Sắp hoàn tất...';
        }
      });
    });
  }

  Future<void> _processImage() async {
    try {
      final repository = ref.read(recognitionRepositoryProvider);

      final result = await repository.recognizeImage(
        imagePath: widget.imagePath,
        modelId: widget.modelId,
        categoryId: widget.categoryId,
      );

      // Also record into history
      ref.read(historyProvider.notifier).addResult(result);

      if (!mounted) return;

      setState(() {
        _progress = 1.0;
        _statusMessage = 'Hoàn tất phân tích!';
      });

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;
      context.go('/result', extra: {
        'result': result,
        'imagePath': widget.imagePath,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
      context.safePop();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: const Text(
                  '🌱',
                  style: TextStyle(fontSize: 80),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 7,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                _statusMessage,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
