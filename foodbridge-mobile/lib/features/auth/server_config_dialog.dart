import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';

class ServerConfigDialog extends ConsumerStatefulWidget {
  const ServerConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const ServerConfigDialog(),
    );
  }

  @override
  ConsumerState<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends ConsumerState<ServerConfigDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final config = ref.read(serverConfigProvider);
    _controller = TextEditingController(text: config.baseUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyPreset(String url) {
    setState(() {
      _controller.text = url;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeConfig = ref.watch(serverConfigProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: const [
          Icon(Icons.dns_rounded, color: AppColors.primary, size: 22),
          SizedBox(width: 8),
          Text(
            'Server Configuration',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the IP address of your FoodBridge FastAPI backend. For physical phones, use your computer\'s Wi-Fi LAN IP.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Backend URL',
                hintText: 'http://192.168.1.105:8000',
                prefixIcon: Icon(Icons.link, size: 20),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            const Text(
              'QUICK PRESETS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.wifi_rounded, size: 16),
                  label: const Text('Wi-Fi LAN (10.56.58.44)'),
                  onPressed: () => _applyPreset('http://10.56.58.44:8000'),
                ),
                ActionChip(
                  label: const Text('Emulator (10.0.2.2)'),
                  onPressed: () => _applyPreset('http://10.0.2.2:8000'),
                ),
                ActionChip(
                  label: const Text('Host (127.0.0.1)'),
                  onPressed: () => _applyPreset('http://127.0.0.1:8000'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Currently connected to: ${activeConfig.baseUrl}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final text = _controller.text.trim();
            if (text.isNotEmpty) {
              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              await ref.read(serverConfigProvider.notifier).updateBaseUrl(text);
              if (mounted) {
                nav.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Server URL set to: $text'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(minimumSize: const Size(100, 40)),
          child: const Text('Save & Apply'),
        ),
      ],
    );
  }
}
