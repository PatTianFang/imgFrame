import 'package:flutter/material.dart';

import '../../domain/photo_asset.dart';

class ExifPanel extends StatelessWidget {
  const ExifPanel({required this.exif, super.key});

  final PhotoExif exif;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('照片参数', style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            _ExifRow(label: '相机', value: exif.cameraLine),
            _ExifRow(label: '焦距', value: exif.focalLength ?? '未读取到'),
            _ExifRow(label: '光圈', value: exif.aperture ?? '未读取到'),
            _ExifRow(label: '快门', value: exif.shutterSpeed ?? '未读取到'),
            _ExifRow(label: 'ISO', value: exif.iso ?? '未读取到'),
            _ExifRow(label: '时间', value: exif.dateLine),
            _ExifRow(label: '位置', value: exif.locationLine),
          ],
        ),
      ),
    );
  }
}

class _ExifRow extends StatelessWidget {
  const _ExifRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
