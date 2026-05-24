import 'dart:ui';

import 'package:flutter/material.dart';

import '../../domain/frame_style.dart';
import '../../domain/photo_asset.dart';

class PhotoPreview extends StatelessWidget {
  const PhotoPreview({required this.photo, required this.style, super.key});

  final PhotoAsset photo;
  final FrameStyle style;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: switch (style) {
        FrameStyle.softGlow => _SoftGlowPreview(photo: photo),
        FrameStyle.whiteInfo => _WhiteInfoPreview(photo: photo),
      },
    );
  }
}

class _SoftGlowPreview extends StatelessWidget {
  const _SoftGlowPreview({required this.photo});

  final PhotoAsset photo;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24);
    return Center(
      child: AspectRatio(
        aspectRatio: _softGlowAspectRatio(photo.aspectRatio),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Image.memory(photo.bytes, fit: BoxFit.cover),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.26),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(34, 34, 34, 72),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 28,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: radius,
                    child: Image.memory(photo.bytes, fit: BoxFit.cover),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 28,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _LeicaMark(size: 26),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        photo.exif.compactExposureLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _softGlowAspectRatio(double imageRatio) {
    final bodyRatio = imageRatio.clamp(0.58, 1.85);
    final bodyHeight = 1 / bodyRatio;
    final canvasHeight = bodyHeight + 0.16;
    return 1 / canvasHeight;
  }
}

class _WhiteInfoPreview extends StatelessWidget {
  const _WhiteInfoPreview({required this.photo});

  final PhotoAsset photo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: _whiteInfoAspectRatio(photo.aspectRatio),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ColoredBox(
            color: Colors.white,
            child: Column(
              children: [
                Expanded(
                  child: SizedBox.expand(
                    child: Image.memory(photo.bytes, fit: BoxFit.cover),
                  ),
                ),
                SizedBox(
                  height: 104,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Row(
                      children: [
                        Expanded(flex: 9, child: _CameraBlock(photo: photo)),
                        const SizedBox(width: 18),
                        const _LeicaMark(size: 44),
                        const SizedBox(width: 18),
                        Container(
                          width: 1.5,
                          height: 58,
                          color: const Color(0xFFDADCE0),
                        ),
                        const SizedBox(width: 22),
                        Expanded(flex: 8, child: _ExposureBlock(photo: photo)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _whiteInfoAspectRatio(double imageRatio) {
    final imageHeight = 1 / imageRatio;
    final totalHeight = imageHeight + 0.16;
    return 1 / totalHeight;
  }
}

class _CameraBlock extends StatelessWidget {
  const _CameraBlock({required this.photo});

  final PhotoAsset photo;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          photo.exif.cameraLine,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          photo.exif.dateLine,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF73777F)),
        ),
      ],
    );
  }
}

class _ExposureBlock extends StatelessWidget {
  const _ExposureBlock({required this.photo});

  final PhotoAsset photo;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          photo.exif.exposureLine,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          photo.exif.locationLine,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF73777F)),
        ),
      ],
    );
  }
}

class _LeicaMark extends StatelessWidget {
  const _LeicaMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final labelSize = size < 32 ? 10.0 : 13.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE50012),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: Text(
            'Leica',
            maxLines: 1,
            style: TextStyle(
              color: Colors.white,
              fontSize: labelSize,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
