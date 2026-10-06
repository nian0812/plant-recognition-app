import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../domain/entities/ai_model.dart';
import '../../widgets/shared_widgets.dart';

class ModelSelectScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final String modeId;

  const ModelSelectScreen({
    super.key,
    required this.categoryId,
    required this.modeId,
  });

  @override
  ConsumerState<ModelSelectScreen> createState() => _ModelSelectScreenState();
}

class _ModelSelectScreenState extends ConsumerState<ModelSelectScreen> {
  String? _selectedModelId;

  @override
  void initState() {
    super.initState();
    _selectedModelId = ref.read(selectedModelIdProvider);
  }

  void _onModelSelected(String modelId) {
    setState(() {
      _selectedModelId = modelId;
    });
    ref.read(selectedModelIdProvider.notifier).state = modelId;
  }

  void _onContinue() {
    if (_selectedModelId == null) return;
    context.push('/category/${widget.categoryId}/mode/${widget.modeId}/model/$_selectedModelId/source');
  }

  @override
  Widget build(BuildContext context) {
    final modelsAsync = ref.watch(modelsForCategoryProvider(widget.categoryId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.safePop(
            fallbackLocation: '/category/${widget.categoryId}/mode',
          ),
        ),
        title: const Text('Chọn mô hình AI'),
      ),
      body: Column(
        children: [
          Expanded(
            child: modelsAsync.when(
              data: (allModels) {
                final isLiveMode = widget.modeId == 'live' || widget.modeId == 'live_camera';
                // Milestone 3O: Live mode only shows models with real Core ML implementation (V4)
                final models = isLiveMode
                    ? allModels.where((m) => m.id.toLowerCase().contains('v4')).toList()
                    : allModels;

                if (models.isEmpty) {
                  return const EmptyStateWidget(
                    emoji: '🤖',
                    title: 'Không có mô hình nào',
                    subtitle: 'Chưa có mô hình AI cho nhóm này.',
                  );
                }

                // If nothing is selected, select the default one initially
                if (_selectedModelId == null) {
                  final defaultModel = models.firstWhere(
                    (m) => m.isDefault,
                    orElse: () => models.first,
                  );
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _onModelSelected(defaultModel.id);
                  });
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: models.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final model = models[index];
                    final isSelected = _selectedModelId == model.id;
                    
                    return GestureDetector(
                      onTap: () => _onModelSelected(model.id),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected ? AppShadows.soft : null,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          model.displayName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (model.isDefault)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryContainer,
                                            borderRadius: BorderRadius.circular(AppRadius.chip),
                                          ),
                                          child: const Text(
                                            'MẶC ĐỊNH',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.secondary,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${model.architecture} • ${model.classCount} classes • ${model.inputSizeLabel}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            // Status indicator
                            Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: model.status == ModelStatus.ready 
                                    ? AppColors.success 
                                    : AppColors.amber,
                              ),
                            ),
                          ],
                        ),
                      ),
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
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: PrimaryButton(
              label: 'Tiếp tục',
              onPressed: _selectedModelId != null ? _onContinue : null,
            ),
          ),
        ],
      ),
    );
  }
}
