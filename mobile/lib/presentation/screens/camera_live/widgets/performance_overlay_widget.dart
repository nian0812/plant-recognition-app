import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Technical performance HUD displaying real-time hardware telemetry and frame scheduler metrics
class PerformanceOverlayWidget extends StatelessWidget {
  final double cameraFps;
  final double aiFps;
  final double latencyMs;
  final String engine;
  final String thermalState;
  final String modelName;

  const PerformanceOverlayWidget({
    super.key,
    required this.cameraFps,
    required this.aiFps,
    required this.latencyMs,
    required this.engine,
    required this.thermalState,
    this.modelName = 'V4 (EfficientNetV2-S)',
  });

  @override
  Widget build(BuildContext context) {
    final thermalColor = switch (thermalState.toLowerCase()) {
      'critical' => Colors.redAccent,
      'serious' => Colors.orangeAccent,
      'fair' => Colors.amberAccent,
      _ => Colors.greenAccent,
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('Camera', '${cameraFps.toStringAsFixed(1)} FPS', Colors.greenAccent),
              _buildMetric('AI', '${aiFps.toStringAsFixed(1)} FPS', Colors.cyanAccent),
              _buildMetric('Độ trễ', '${latencyMs.toStringAsFixed(0)} ms', Colors.yellowAccent),
              _buildMetric('Nhiệt độ', thermalState, thermalColor),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(height: 8, color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mô hình: $modelName • 384×384',
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
              Text(
                'Phần cứng: $engine',
                style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        Text(
          value,
          style: TextStyle(color: valueColor, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
