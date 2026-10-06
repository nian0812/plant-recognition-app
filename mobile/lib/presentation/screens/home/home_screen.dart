import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/pvz_sunflower_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nhận dạng thực vật',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      CircleIconButton(
                        icon: Icons.history,
                        onPressed: () => context.push('/history'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      CircleIconButton(
                        icon: Icons.settings_outlined,
                        onPressed: () => context.push('/settings'),
                      ),
                    ],
                  )
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  // Hero Banner with animated PvZ Sunflower
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 165),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.xxl),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const StatusBadge(
                                label: 'NỀN TẢNG AI ĐA DANH MỤC',
                                isReady: true,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.52,
                                child: const Text(
                                  'Nhận dạng thế giới thực vật & sinh vật',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.52,
                                child: const Text(
                                  'Phân loại học thông minh với AI On-Device',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Sunflower mascot animation
                        const Positioned(
                          right: 8,
                          bottom: 4,
                          child: PvZSunflowerWidget(size: 115),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Active Model Indicator
                  categoriesAsync.when(
                    data: (categories) {
                      final activeCategory = categories.firstWhere(
                        (c) => c.isAvailable,
                        orElse: () => categories.first,
                      );
                      final modelAsync =
                          ref.watch(defaultModelProvider(activeCategory.id));

                      return modelAsync.when(
                        data: (model) => Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Mô hình cục bộ:',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      model != null
                                          ? '${model.displayName} (${model.architecture})'
                                          : 'Đang tải...',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  context.push(
                                    '/category/${activeCategory.id}/mode/single_image/model',
                                  );
                                },
                                child: const Text(
                                  'Đổi >',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const SizedBox(),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox(),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                  const Text(
                    'Bạn muốn nhận dạng gì?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Bento Grid
                  categoriesAsync.when(
                    data: (categories) {
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          childAspectRatio: 1.15,
                        ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return BentoCard(
                            emoji: category.emoji,
                            title: category.name,
                            subtitle: category.description,
                            statusLabel: category.statusLabel ??
                                (category.isAvailable ? 'SẴN SÀNG' : 'SẮP CÓ'),
                            isAvailable: category.isAvailable,
                            isActive: category.id == 'flowers',
                            onTap: () {
                              if (category.isAvailable) {
                                context.push('/category/${category.id}');
                              }
                            },
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) =>
                        ErrorStateWidget(message: err.toString()),
                  ),
                  const SizedBox(height: 100), // Padding for bottom button
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: categoriesAsync.maybeWhen(
        data: (categories) {
          final firstAvailable = categories.firstWhere(
            (c) => c.isAvailable,
            orElse: () => categories.first,
          );
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: PrimaryButton(
              label: '📷  Nhận dạng ngay',
              onPressed: () {
                if (firstAvailable.isAvailable) {
                  context.push('/category/${firstAvailable.id}/mode');
                }
              },
            ),
          );
        },
        orElse: () => const SizedBox(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
