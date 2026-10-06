import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../domain/entities/recognition_mode.dart';
import '../../widgets/shared_widgets.dart';

class ModeSelectScreen extends ConsumerWidget {
  final String categoryId;

  const ModeSelectScreen({
    super.key,
    required this.categoryId,
  });

  void _onModeSelected(
    BuildContext context,
    WidgetRef ref,
    RecognitionMode mode,
  ) {
    if (!mode.isAvailable) return;

    ref.read(selectedModeIdProvider.notifier).state = mode.id;

    if (mode.type == RecognitionModeType.liveCamera) {
      context.push(
        '/camera-live',
        extra: {
          'categoryId': categoryId,
          'modelId': 'v4',
        },
      );
    } else {
      context.push('/category/$categoryId/mode/${mode.id}/model');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryAsync = ref.watch(categoryProvider(categoryId));
    final modesAsync = ref.watch(modesForCategoryProvider(categoryId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.safePop(fallbackLocation: '/category/$categoryId'),
        ),
        title: categoryAsync.when(
          data: (category) =>
              Text('Phương thức • Nhóm ${category?.name ?? ""}'),
          loading: () => const Text('Phương thức'),
          error: (_, __) => const Text('Phương thức'),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Chọn cách thức AI xử lý hình ảnh:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: modesAsync.when(
              data: (modes) {
                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: modes.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final mode = modes[index];
                    return _ModeCard(
                      mode: mode,
                      onTap: () => _onModeSelected(context, ref, mode),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => ErrorStateWidget(message: err.toString()),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: AppColors.primaryContainer,
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.secondary,
                  size: 20,
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Trung thực học thuật: Không dùng model Phân loại để vẽ Bounding Box giả lập cho Quét đối tượng.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final RecognitionMode mode;
  final VoidCallback onTap;

  const _ModeCard({
    required this.mode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = mode.isAvailable;

    Widget content = Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.white : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isAvailable ? AppColors.secondary : AppColors.border,
          width: isAvailable ? 1.5 : 1.0,
        ),
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mode.emoji,
                style: TextStyle(
                  fontSize: 28,
                  color: isAvailable ? null : Colors.grey,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isAvailable
                            ? AppColors.textPrimary
                            : AppColors.textDisabled,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isAvailable
                            ? AppColors.textSecondary
                            : AppColors.textDisabled,
                      ),
                    ),
                    if (mode.supportInfo != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        mode.supportInfo!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isAvailable
                              ? AppColors.secondary
                              : AppColors.textDisabled,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (mode.statusLabel != null)
            Positioned(
              top: 0,
              right: 0,
              child: StatusBadge(
                label: mode.statusLabel!,
                isReady: isAvailable,
              ),
            ),
        ],
      ),
    );

    if (!isAvailable) {
      content = Opacity(
        opacity: 0.85,
        child: content,
      );
    }

    return GestureDetector(
      onTap: isAvailable ? onTap : null,
      child: content,
    );
  }
}
