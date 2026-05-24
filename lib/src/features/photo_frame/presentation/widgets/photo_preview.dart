import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../domain/frame_layout.dart';
import '../../domain/frame_options.dart';
import '../../domain/frame_style.dart';
import '../../domain/photo_asset.dart';
import 'leica_badge.dart';

class PhotoPreview extends StatelessWidget {
  const PhotoPreview({
    required this.photo,
    required this.style,
    required this.options,
    super.key,
  });

  final PhotoAsset photo;
  final FrameStyle style;
  final FrameOptions options;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: switch (style) {
        FrameStyle.softGlow => _SoftGlowPreview(
          key: ValueKey(('softGlow', options)),
          photo: photo,
          options: options,
        ),
        FrameStyle.whiteInfo => _WhiteInfoPreview(
          key: ValueKey(('whiteInfo', options)),
          photo: photo,
          options: options,
        ),
      },
    );
  }
}

class _SoftGlowPreview extends StatelessWidget {
  const _SoftGlowPreview({
    required this.photo,
    required this.options,
    super.key,
  });

  final PhotoAsset photo;
  final FrameOptions options;

  @override
  Widget build(BuildContext context) {
    final layout = FrameLayoutMetrics.softGlow(
      photoWidth: photo.width,
      photoHeight: photo.height,
      options: options,
    );
    return Center(
      child: AspectRatio(
        aspectRatio: layout.aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = constraints.maxWidth / layout.canvasWidth;
              return Stack(
                fit: StackFit.expand,
                children: [
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: math.max(1, 18 * scale),
                      sigmaY: math.max(1, 18 * scale),
                    ),
                    child: Image.memory(photo.bytes, fit: BoxFit.cover),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.26),
                    ),
                  ),
                  Positioned(
                    left: layout.photoX * scale,
                    top: layout.photoY * scale,
                    width: layout.photoWidth * scale,
                    height: layout.photoHeight * scale,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          layout.cornerRadius * scale,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 28 * scale,
                            offset: Offset(0, 16 * scale),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          layout.cornerRadius * scale,
                        ),
                        child: Image.memory(photo.bytes, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  Positioned(
                    left: layout.marginX * scale,
                    right: layout.marginX * scale,
                    top: (layout.logoCenterY - layout.logoSize / 2) * scale,
                    height: layout.logoSize * scale,
                    child: _SoftInfoRow(
                      text: options.softInfoLine(photo.exif),
                      alignment: options.badgeAlignment,
                      logoSize: layout.logoSize * scale,
                      textGap: layout.logoTextGap * scale,
                      fontSize: layout.primaryFontSize * scale,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WhiteInfoPreview extends StatelessWidget {
  const _WhiteInfoPreview({
    required this.photo,
    required this.options,
    super.key,
  });

  final PhotoAsset photo;
  final FrameOptions options;

  @override
  Widget build(BuildContext context) {
    final layout = FrameLayoutMetrics.whiteInfo(
      photoWidth: photo.width,
      photoHeight: photo.height,
      options: options,
    );
    return Center(
      child: AspectRatio(
        aspectRatio: layout.aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = constraints.maxWidth / layout.canvasWidth;
              return ColoredBox(
                color: Colors.white,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      left: layout.photoX * scale,
                      top: layout.photoY * scale,
                      width: layout.photoWidth * scale,
                      height: layout.photoHeight * scale,
                      child: Image.memory(photo.bytes, fit: BoxFit.cover),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: layout.infoY * scale,
                      height: layout.infoHeight * scale,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAF9),
                          border: Border(
                            top: BorderSide(
                              color: const Color(0xFFE4E6EA),
                              width: math.max(1, scale),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: (layout.logoCenterX - layout.logoSize / 2) * scale,
                      top: (layout.logoCenterY - layout.logoSize / 2) * scale,
                      width: layout.logoSize * scale,
                      height: layout.logoSize * scale,
                      child: LeicaBadge(size: layout.logoSize * scale),
                    ),
                    ..._infoBlocks(layout, scale),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _infoBlocks(FrameLayoutMetrics layout, double scale) {
    if (options.badgeAlignment == LeicaBadgeAlignment.center) {
      final logoOffset = layout.logoSize ~/ 2 + layout.logoTextGap;
      final leftMaxWidth = layout.logoCenterX - logoOffset - layout.marginX;
      final rightX = layout.logoCenterX + logoOffset;
      final rightMaxWidth = layout.canvasWidth - layout.marginX - rightX;
      return [
        _InfoBlock(
          primary: options.cameraInfoLine(photo.exif),
          secondary: options.dateInfoLine(photo.exif),
          x: layout.marginX,
          maxWidth: leftMaxWidth,
          layout: layout,
          scale: scale,
        ),
        _InfoBlock(
          primary: options.exposureInfoLine(photo.exif),
          secondary: options.locationInfoLine(photo.exif),
          x: rightX,
          maxWidth: rightMaxWidth,
          layout: layout,
          scale: scale,
        ),
      ];
    }
    if (options.badgeAlignment == LeicaBadgeAlignment.left) {
      final x = layout.logoCenterX + layout.logoSize ~/ 2 + layout.logoTextGap;
      return [
        _InfoBlock(
          primary: options.combinedPrimaryInfoLine(photo.exif),
          secondary: options.combinedSecondaryInfoLine(photo.exif),
          x: x,
          maxWidth: layout.canvasWidth - layout.marginX - x,
          layout: layout,
          scale: scale,
        ),
      ];
    }
    final maxWidth =
        layout.logoCenterX -
        layout.logoSize ~/ 2 -
        layout.logoTextGap -
        layout.marginX;
    return [
      _InfoBlock(
        primary: options.combinedPrimaryInfoLine(photo.exif),
        secondary: options.combinedSecondaryInfoLine(photo.exif),
        x: layout.marginX,
        maxWidth: maxWidth,
        layout: layout,
        scale: scale,
      ),
    ];
  }
}

class _SoftInfoRow extends StatelessWidget {
  const _SoftInfoRow({
    required this.text,
    required this.alignment,
    required this.logoSize,
    required this.textGap,
    required this.fontSize,
  });

  final String text;
  final LeicaBadgeAlignment alignment;
  final double logoSize;
  final double textGap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final textWidget = Flexible(
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          height: 1,
        ),
      ),
    );
    final gap = text.isEmpty
        ? const SizedBox.shrink()
        : SizedBox(width: textGap);
    final logo = LeicaBadge(size: logoSize);
    return Row(
      mainAxisAlignment: switch (alignment) {
        LeicaBadgeAlignment.left => MainAxisAlignment.start,
        LeicaBadgeAlignment.center => MainAxisAlignment.center,
        LeicaBadgeAlignment.right => MainAxisAlignment.end,
      },
      children: alignment == LeicaBadgeAlignment.right
          ? [if (text.isNotEmpty) textWidget, gap, logo]
          : [logo, gap, if (text.isNotEmpty) textWidget],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.primary,
    required this.secondary,
    required this.x,
    required this.maxWidth,
    required this.layout,
    required this.scale,
  });

  final String primary;
  final String secondary;
  final int x;
  final int maxWidth;
  final FrameLayoutMetrics layout;
  final double scale;

  @override
  Widget build(BuildContext context) {
    if (maxWidth <= 0 || (primary.isEmpty && secondary.isEmpty)) {
      return const SizedBox.shrink();
    }
    final hasPrimary = primary.isNotEmpty;
    return Positioned(
      left: x * scale,
      top:
          (hasPrimary
              ? layout.primaryTextY
              : layout.logoCenterY - layout.secondaryFontSize / 2) *
          scale,
      width: maxWidth * scale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPrimary)
            Text(
              primary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF101216),
                fontSize: layout.primaryFontSize * scale,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          if (hasPrimary && secondary.isNotEmpty)
            SizedBox(height: layout.lineGap * scale),
          if (secondary.isNotEmpty)
            Text(
              secondary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF787C82),
                fontSize: layout.secondaryFontSize * scale,
                height: 1,
              ),
            ),
        ],
      ),
    );
  }
}
