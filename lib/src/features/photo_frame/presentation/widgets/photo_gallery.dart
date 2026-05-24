import 'package:flutter/material.dart';

import '../../domain/photo_asset.dart';

class PhotoGallery extends StatelessWidget {
  const PhotoGallery({
    required this.photos,
    required this.selectedIndex,
    required this.onSelected,
    required this.horizontal,
    super.key,
  });

  final List<PhotoAsset> photos;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final list = ListView.separated(
      padding: const EdgeInsets.all(16),
      scrollDirection: horizontal ? Axis.horizontal : Axis.vertical,
      itemCount: photos.length,
      separatorBuilder: (_, _) =>
          SizedBox(width: horizontal ? 12 : 0, height: horizontal ? 0 : 12),
      itemBuilder: (context, index) {
        return _PhotoTile(
          photo: photos[index],
          selected: index == selectedIndex,
          horizontal: horizontal,
          onTap: () => onSelected(index),
        );
      },
    );

    return DecoratedBox(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: list,
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.selected,
    required this.horizontal,
    required this.onTap,
  });

  final PhotoAsset photo;
  final bool selected;
  final bool horizontal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = selected
        ? colorScheme.primary
        : colorScheme.outlineVariant;
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: horizontal ? 96 : double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: selected ? colorScheme.primaryContainer : colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: selected ? 2 : 1),
      ),
      child: horizontal
          ? _Thumbnail(photo: photo)
          : Row(
              children: [
                SizedBox.square(dimension: 68, child: _Thumbnail(photo: photo)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photo.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        photo.exif.compactExposureLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );

    return Tooltip(
      message: photo.name,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.photo});

  final PhotoAsset photo;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.memory(
        photo.bytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }
}
