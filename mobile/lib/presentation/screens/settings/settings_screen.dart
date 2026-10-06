import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showEditUrlDialog(BuildContext context, WidgetRef ref, String currentUrl) {
    final controller = TextEditingController(text: currentUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cấu hình API Backend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập địa chỉ máy chủ ASP.NET Core:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'http://localhost:5217 hoặc IP LAN',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Android Emulator: http://10.0.2.2:5217\n• Windows/Web: http://localhost:5217\n• Thiết bị thật: http://<IP_LAN>:5217',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                ref.read(apiBaseUrlProvider.notifier).state = newUrl;
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useApi = ref.watch(useApiProvider);
    final baseUrl = ref.watch(apiBaseUrlProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _buildSection(
            title: 'Kết nối ASP.NET Core Backend',
            children: [
              ListTile(
                leading: const Icon(Icons.cloud_sync_outlined),
                title: const Text('Sử dụng API Backend'),
                subtitle: Text(
                  useApi
                      ? 'Đang kết nối: $baseUrl'
                      : 'Đang chạy chế độ Mock độc lập',
                ),
                trailing: Switch(
                  value: useApi,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) {
                    ref.read(useApiProvider.notifier).state = val;
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dns_outlined),
                title: const Text('Địa chỉ máy chủ (Base URL)'),
                subtitle: Text(baseUrl, style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.edit_outlined, size: 20),
                onTap: () => _showEditUrlDialog(context, ref, baseUrl),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildSection(
            title: 'Giao diện & Trải nghiệm',
            children: [
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: const Text('Chế độ tối'),
                subtitle: const Text('Mặc định: Giao diện sáng (Botanical)'),
                trailing: Switch(
                  value: false,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildSection(
            title: 'Ngôn ngữ',
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Ngôn ngữ hiển thị'),
                trailing: const Text(
                  'Tiếng Việt',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildSection(
            title: 'Nhận dạng & Mô hình',
            children: [
              ListTile(
                leading: const Icon(Icons.psychology_outlined),
                title: const Text('Mô hình mặc định'),
                trailing: const Text(
                  'Flower V4',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.format_list_numbered),
                title: const Text('Số lượng kết quả Top-N'),
                trailing: const Text(
                  'Top 3',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildSection(
            title: 'Hiệu suất & Phần cứng (Quan trọng)',
            children: [
              ListTile(
                leading: const Icon(Icons.speed, color: AppColors.primary),
                title: const Text(
                  'Cài đặt hiệu suất & Phần cứng',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Camera FPS, AI FPS, Engine, Live Overlay'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/performance'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildSection(
            title: 'Về ứng dụng',
            children: [
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Plant Recognition Platform'),
                subtitle: Text('Phiên bản 2.0.0 (Tích hợp ASP.NET Core AI)'),
                trailing: Text(
                  'v2.0.0',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}
