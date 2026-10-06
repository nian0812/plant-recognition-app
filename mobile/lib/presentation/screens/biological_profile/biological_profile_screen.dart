import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../domain/entities/plant_profile.dart';
import '../../widgets/shared_widgets.dart';

class BiologicalProfileScreen extends ConsumerWidget {
  final int classId;

  const BiologicalProfileScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(plantProfileRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: CircleIconButton(
          icon: Icons.arrow_back,
          onPressed: () => context.safePop(),
        ),
        title: const Text('Hồ sơ sinh học'),
        centerTitle: true,
      ),
      body: FutureBuilder<PlantProfile?>(
        future: repository.getProfileByClassId(classId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text(
                'Không tìm thấy thông tin sinh học cho loài này.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          final profile = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, profile),
                const SizedBox(height: AppSpacing.lg),
                _buildTaxonomyCard(context, profile),
                const SizedBox(height: AppSpacing.lg),
                if (profile.description != null &&
                    profile.description!.isNotEmpty)
                  _buildSection(
                    context,
                    'Mô tả sinh học',
                    profile.description!,
                    Icons.description_outlined,
                  ),
                const SizedBox(height: AppSpacing.lg),
                if (profile.characteristics != null &&
                    profile.characteristics!.isNotEmpty)
                  _buildCharacteristicsSection(
                    context,
                    profile.characteristics!,
                  ),
                const SizedBox(height: AppSpacing.lg),
                if (profile.distribution != null &&
                    profile.distribution!.isNotEmpty)
                  _buildSection(
                    context,
                    'Khu vực phân bố',
                    profile.distribution!,
                    Icons.public_outlined,
                  ),
                const SizedBox(height: AppSpacing.lg),
                if (profile.uses != null && profile.uses!.isNotEmpty)
                  _buildSection(
                    context,
                    'Công dụng & Giá trị',
                    profile.uses!,
                    Icons.spa_outlined,
                  ),
                const SizedBox(height: AppSpacing.lg),
                if (profile.notes != null && profile.notes!.isNotEmpty)
                  _buildSection(
                    context,
                    'Lưu ý chăm sóc / Dược tính',
                    profile.notes!,
                    Icons.warning_amber_rounded,
                  ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PlantProfile profile) {
    return Column(
      children: [
        Container(
          height: 110,
          width: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceVariant,
            border: Border.all(color: AppColors.border, width: 2),
            boxShadow: AppShadows.soft,
          ),
          clipBehavior: Clip.antiAlias,
          child: profile.imageUrl != null && profile.imageUrl!.isNotEmpty
              ? Image.network(
                  profile.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text('🌸', style: TextStyle(fontSize: 48)),
                  ),
                )
              : const Center(
                  child: Text('🌸', style: TextStyle(fontSize: 48)),
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          profile.nameVi,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        if (profile.scientificName != null) ...[
          const SizedBox(height: 2),
          Text(
            profile.scientificName!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildTaxonomyCard(BuildContext context, PlantProfile profile) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          _buildTaxonomyRow(
            'Họ (Family)',
            '${profile.familyVi ?? ""} ${profile.family != null ? "(${profile.family})" : ""}'
                .trim(),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(color: AppColors.border),
          ),
          _buildTaxonomyRow(
            'Chi (Genus)',
            profile.genus ?? 'Chưa xác định',
          ),
        ],
      ),
    );
  }

  Widget _buildTaxonomyRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
  ) {
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
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            content,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacteristicsSection(
    BuildContext context,
    List<String> points,
  ) {
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
          const Row(
            children: [
              Icon(Icons.grass, color: AppColors.primary, size: 20),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Đặc điểm hình thái',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
