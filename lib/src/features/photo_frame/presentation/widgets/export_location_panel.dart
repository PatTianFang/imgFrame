import 'package:flutter/material.dart';

class ExportLocationPanel extends StatelessWidget {
  const ExportLocationPanel({
    required this.locationLabel,
    required this.locationHint,
    required this.canChooseDirectory,
    required this.usesCustomDirectory,
    required this.onChooseDirectory,
    required this.onResetDirectory,
    super.key,
  });

  final String locationLabel;
  final String locationHint;
  final bool canChooseDirectory;
  final bool usesCustomDirectory;
  final VoidCallback onChooseDirectory;
  final VoidCallback onResetDirectory;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.folder_open_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('导出位置', style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(
              locationLabel,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              locationHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canChooseDirectory)
                  OutlinedButton.icon(
                    onPressed: onChooseDirectory,
                    icon: const Icon(Icons.create_new_folder_outlined),
                    label: const Text('选择目录'),
                  ),
                if (canChooseDirectory && usesCustomDirectory)
                  TextButton.icon(
                    onPressed: onResetDirectory,
                    icon: const Icon(Icons.restart_alt_outlined),
                    label: const Text('恢复默认'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
