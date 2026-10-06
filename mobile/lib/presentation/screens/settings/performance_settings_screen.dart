import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/performance_settings.dart';

class PerformanceSettingsScreen extends ConsumerWidget {
  const PerformanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(performanceSettingsProvider);
    final notifier = ref.read(performanceSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hiệu suất & Phần cứng'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // AI Engine Status Card
          Card(
            color: AppColors.surfaceVariant,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.memory, color: AppColors.primary),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        'AI Engine Hardware Status',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildEngineRow('Chế độ Engine:', 'Automatic'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        'Trạng thái tăng tốc: ',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.amberLight,
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        child: const Text(
                          'Sẵn sàng (Phase sau tích hợp)',
                          style: TextStyle(
                            color: AppColors.amber,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Lưu ý học thuật: Core ML / Neural Engine và ONNX Mobile Runtime sẽ được tích hợp ở phase sau khi có model runtime thật.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          _buildSectionTitle('Hiệu năng tổng thể'),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Adaptive Performance (Mặc định: BẬT)'),
                  subtitle: const Text(
                    'Tự động điều tiết tốc độ AI dựa theo nhiệt độ và mức pin máy',
                  ),
                  value: settings.adaptivePerformance,
                  activeThumbColor: AppColors.primary,
                  onChanged: (_) => notifier.toggleAdaptivePerformance(),
                ),
                const Divider(color: AppColors.border),
                SwitchListTile(
                  title: const Text('Live Performance Overlay'),
                  subtitle: const Text(
                    'Hiển thị Camera FPS, AI FPS, thời gian suy luận (ms) trên Live Screen',
                  ),
                  value: settings.showPerformanceOverlay,
                  activeThumbColor: AppColors.primary,
                  onChanged: (_) => notifier.togglePerformanceOverlay(),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
          _buildSectionTitle('Tần số quét Camera & Tốc độ AI'),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildDropdownOption<CameraFpsOption>(
                  title: 'Camera FPS',
                  subtitle: 'Tốc độ khung hình của cảm biến camera',
                  value: settings.cameraFps,
                  items: CameraFpsOption.values,
                  labelBuilder: (v) {
                    switch (v) {
                      case CameraFpsOption.auto:
                        return 'Tự động (Auto)';
                      case CameraFpsOption.fps30:
                        return '30 FPS';
                      case CameraFpsOption.fps60:
                        return '60 FPS (nếu máy hỗ trợ)';
                    }
                  },
                  onChanged: (val) {
                    if (val != null) notifier.updateCameraFps(val);
                  },
                ),
                const Divider(color: AppColors.border),
                _buildDropdownOption<AiInferenceFps>(
                  title: 'AI Inference FPS',
                  subtitle: 'Tần số lấy mẫu và gửi frame vào mô hình AI',
                  value: settings.aiInferenceFps,
                  items: AiInferenceFps.values,
                  labelBuilder: (v) {
                    switch (v) {
                      case AiInferenceFps.auto:
                        return 'Tự động (Throttled)';
                      case AiInferenceFps.fps5:
                        return '5 FPS (Tiết kiệm pin)';
                      case AiInferenceFps.fps10:
                        return '10 FPS';
                      case AiInferenceFps.fps15:
                        return '15 FPS';
                      case AiInferenceFps.fps20:
                        return '20 FPS';
                      case AiInferenceFps.fps30:
                        return '30 FPS (Tải cao)';
                    }
                  },
                  onChanged: (val) {
                    if (val != null) notifier.updateAiInferenceFps(val);
                  },
                ),
                const Divider(color: AppColors.border),
                _buildDropdownOption<PerformanceMode>(
                  title: 'Chế độ hiệu năng',
                  subtitle: 'Cân bằng giữa tốc độ nhận dạng và điện năng tiêu thụ',
                  value: settings.performanceMode,
                  items: PerformanceMode.values,
                  labelBuilder: (v) {
                    switch (v) {
                      case PerformanceMode.auto:
                        return 'Tự động (Auto)';
                      case PerformanceMode.highPerformance:
                        return 'Hiệu năng cao (High Performance)';
                      case PerformanceMode.balanced:
                        return 'Cân bằng (Balanced)';
                      case PerformanceMode.batterySaver:
                        return 'Tiết kiệm pin (Battery Saver)';
                    }
                  },
                  onChanged: (val) {
                    if (val != null) notifier.updatePerformanceMode(val);
                  },
                ),
                const Divider(color: AppColors.border),
                _buildDropdownOption<CameraResolution>(
                  title: 'Độ phân giải Camera',
                  subtitle: 'Kích thước khung hình thu nhận từ ống kính',
                  value: settings.cameraResolution,
                  items: CameraResolution.values,
                  labelBuilder: (v) {
                    switch (v) {
                      case CameraResolution.auto:
                        return 'Tự động (Auto)';
                      case CameraResolution.hd:
                        return 'HD (720p)';
                      case CameraResolution.fullHd:
                        return 'Full HD (1080p)';
                      case CameraResolution.highest:
                        return 'Cao nhất hỗ trợ';
                    }
                  },
                  onChanged: (val) {
                    if (val != null) notifier.updateCameraResolution(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildEngineRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDropdownOption<T extends Enum>({
    required String title,
    required String subtitle,
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required void Function(T?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          DropdownButton<T>(
            value: value,
            underline: const SizedBox(),
            items: items.map((T item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(
                  labelBuilder(item),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
