import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../../domain/entities/recognition_result.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> extra;

  const ResultScreen({super.key, required this.extra});

  static RecognitionResult _defaultResult() => RecognitionResult(
        success: true,
        classId: 'Helianthus_annuus',
        nameVi: 'Hoa Hướng Dương',
        nameEn: 'Sunflower',
        scientificName: 'Helianthus annuus',
        confidence: 0.9421,
        modelId: 'v4',
        modelName: 'Flower Recognition V4 (EfficientNetV2-S)',
        inferenceTimeMs: 42.5,
        topPredictions: const [
          PredictionDetail(
            classId: 'Helianthus_annuus',
            nameVi: 'Hoa Hướng Dương',
            nameEn: 'Sunflower',
            scientificName: 'Helianthus annuus',
            confidence: 0.9421,
          ),
          PredictionDetail(
            classId: 'Chrysanthemum',
            nameVi: 'Hoa Cúc Vàng',
            nameEn: 'Yellow Daisy',
            scientificName: 'Chrysanthemum',
            confidence: 0.0315,
          ),
          PredictionDetail(
            classId: 'Tagetes_erecta',
            nameVi: 'Hoa Vạn Thọ',
            nameEn: 'Marigold',
            scientificName: 'Tagetes erecta',
            confidence: 0.0124,
          ),
        ],
        timestamp: DateTime.now(),
      );

  @override
  Widget build(BuildContext context) {
    final result = (extra['result'] as RecognitionResult?) ?? _defaultResult();
    final imagePath = extra['imagePath'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: CircleIconButton(
          icon: Icons.close,
          onPressed: () => context.go('/'),
        ),
        title: const Text('Kết quả phân tích'),
        centerTitle: true,
        actions: [
          CircleIconButton(
            icon: Icons.share_outlined,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép kết quả')),
              );
            },
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageHeader(context, imagePath, result),
            const SizedBox(height: AppSpacing.lg),
            _buildResultCard(context, result),
            const SizedBox(height: AppSpacing.lg),
            SecondaryButton(
              label: '📖  Xem hồ sơ sinh học >',
              onPressed: () =>
                  context.push('/biological-profile/${result.classId}'),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: '📷  Nhận dạng mẫu khác',
              onPressed: () => context.go('/'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHeader(
      BuildContext context, String imagePath, RecognitionResult result) {
    Widget imageWidget = _buildPlaceholder();
    if (!kIsWeb && imagePath.isNotEmpty) {
      try {
        final file = io.File(imagePath);
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder(),
          );
        }
      } catch (_) {
        imageWidget = _buildPlaceholder();
      }
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.soft,
        color: AppColors.darkSurface,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageWidget,

          Positioned(
            bottom: AppSpacing.md,
            left: AppSpacing.md,
            child: Row(
              children: [
                _buildBadge('Nhóm: 🌸 Hoa', AppColors.primary),
                const SizedBox(width: AppSpacing.xs),
                _buildBadge(
                  result.isFromApi
                      ? '● ASP.NET Core AI'
                      : '● On-Device AI (Mock)',
                  result.isFromApi ? AppColors.secondary : AppColors.amber,
                ),
              ],
            ),
          ),
          Positioned(
            top: AppSpacing.md,
            right: AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.zoom_in, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.7),
            AppColors.secondary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.local_florist, size: 54, color: Colors.white),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, RecognitionResult result) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.nameVi,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            result.scientificName ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: result.isFromApi
                      ? AppColors.primaryContainer
                      : AppColors.amberLight,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  result.isFromApi ? '🌐 API Thật' : '⚡ Mock Fallback',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: result.isFromApi
                        ? AppColors.secondary
                        : AppColors.amber,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  'Mô hình: ${result.modelName}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (result.inferenceTimeMs != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    '${result.inferenceTimeMs!.toStringAsFixed(1)} ms',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(color: AppColors.border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Độ tin cậy (Confidence)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    result.confidencePercent,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              ConfidenceCircle(
                confidence: result.confidence,
                size: 52,
                strokeWidth: 5,
              ),
            ],
          ),
          if (result.topPredictions != null &&
              result.topPredictions!.length > 1) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(color: AppColors.border),
            ),
            const Text(
              'Các dự đoán gần nhất:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...result.topPredictions!.skip(1).map((pred) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      pred.nameVi,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      pred.confidencePercent,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
