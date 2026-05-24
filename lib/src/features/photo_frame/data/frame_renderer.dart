import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../domain/frame_style.dart';
import '../domain/photo_asset.dart';

class FrameRenderer {
  const FrameRenderer._();

  static Future<Uint8List> render(PhotoAsset photo, FrameStyle style) async {
    return compute(_renderOnIsolate, <String, Object?>{
      'bytes': photo.bytes,
      'name': photo.name,
      'style': style.name,
      'exif': photo.exif.toMap(),
    });
  }

  static Uint8List _renderOnIsolate(Map<String, Object?> payload) {
    final bytes = payload['bytes']! as Uint8List;
    final name = payload['name']! as String;
    final style = FrameStyle.values.byName(payload['style']! as String);
    final exifMap = Map<String, Object?>.from(payload['exif']! as Map);
    final exif = PhotoExif.fromMap(exifMap);
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('Unsupported image format: $name');
    }
    final source = img.bakeOrientation(decoded);
    final output = switch (style) {
      FrameStyle.softGlow => _renderSoftGlow(source, exif),
      FrameStyle.whiteInfo => _renderWhiteInfo(source, exif),
    };
    return Uint8List.fromList(img.encodePng(output));
  }

  static img.Image _renderSoftGlow(img.Image source, PhotoExif exif) {
    const canvasWidth = 1440;
    const sidePadding = 72;
    const topPadding = 72;
    const bottomPadding = 170;
    const cornerRadius = 28;
    final photoWidth = canvasWidth - sidePadding * 2;
    final photoHeight = (photoWidth * source.height / source.width).round();
    final canvasHeight = topPadding + photoHeight + bottomPadding;

    final background = _coverResize(source, canvasWidth, canvasHeight);
    img.gaussianBlur(background, radius: 28);
    img.fillRect(
      background,
      x1: 0,
      y1: 0,
      x2: canvasWidth - 1,
      y2: canvasHeight - 1,
      color: _rgba(12, 18, 14, 116),
    );

    final shadow = img.Image(
      width: canvasWidth,
      height: canvasHeight,
      numChannels: 4,
    );
    img.fill(shadow, color: _rgba(0, 0, 0, 0));
    img.fillRect(
      shadow,
      x1: sidePadding + 10,
      y1: topPadding + 24,
      x2: sidePadding + photoWidth - 10,
      y2: topPadding + photoHeight + 36,
      color: _rgba(0, 0, 0, 126),
      radius: cornerRadius,
    );
    img.gaussianBlur(shadow, radius: 24);
    img.compositeImage(background, shadow);

    final framedPhoto = img
        .copyResize(
          source,
          width: photoWidth,
          interpolation: img.Interpolation.cubic,
        )
        .convert(numChannels: 4, alpha: 255);
    _roundCorners(framedPhoto, cornerRadius);
    img.compositeImage(
      background,
      framedPhoto,
      dstX: sidePadding,
      dstY: topPadding,
    );

    final logoY = topPadding + photoHeight + 72;
    final text = exif.compactExposureLine;
    final logoRadius = 22;
    final textWidth = _textWidth(img.arial24, text);
    final groupWidth = logoRadius * 2 + 22 + textWidth;
    final startX = ((canvasWidth - groupWidth) / 2).round();
    _drawLeicaLogo(background, startX + logoRadius, logoY, logoRadius);
    img.drawString(
      background,
      text,
      font: img.arial24,
      x: startX + logoRadius * 2 + 22,
      y: logoY - 12,
      color: _rgb(244, 247, 242),
    );

    return background;
  }

  static img.Image _renderWhiteInfo(img.Image source, PhotoExif exif) {
    const canvasWidth = 1440;
    const infoHeight = 230;
    final photoHeight = (canvasWidth * source.height / source.width).round();
    final canvasHeight = photoHeight + infoHeight;
    final canvas = img.Image(width: canvasWidth, height: canvasHeight);
    img.fill(canvas, color: _rgb(255, 255, 255));

    final framedPhoto = img.copyResize(
      source,
      width: canvasWidth,
      interpolation: img.Interpolation.cubic,
    );
    img.compositeImage(canvas, framedPhoto);

    img.fillRect(
      canvas,
      x1: 0,
      y1: photoHeight,
      x2: canvasWidth - 1,
      y2: canvasHeight - 1,
      color: _rgb(255, 255, 255),
    );

    final baseline = photoHeight + 52;
    img.drawString(
      canvas,
      _truncateAscii(exif.cameraLine, 35),
      font: img.arial48,
      x: 64,
      y: baseline,
      color: _rgb(16, 18, 22),
    );
    img.drawString(
      canvas,
      exif.dateLine,
      font: img.arial24,
      x: 64,
      y: baseline + 72,
      color: _rgb(120, 124, 130),
    );

    final logoCenterX = canvasWidth - 592;
    final logoCenterY = photoHeight + infoHeight ~/ 2;
    _drawLeicaLogo(canvas, logoCenterX, logoCenterY, 42);
    img.drawLine(
      canvas,
      x1: logoCenterX + 84,
      y1: photoHeight + 48,
      x2: logoCenterX + 84,
      y2: canvasHeight - 48,
      color: _rgb(194, 196, 201),
      thickness: 3,
    );

    final rightX = logoCenterX + 124;
    img.drawString(
      canvas,
      _truncateAscii(exif.exposureLine, 38),
      font: img.arial48,
      x: rightX,
      y: baseline,
      color: _rgb(18, 20, 24),
    );
    img.drawString(
      canvas,
      exif.locationLine,
      font: img.arial24,
      x: rightX,
      y: baseline + 72,
      color: _rgb(120, 124, 130),
    );

    return canvas;
  }

  static img.Image _coverResize(img.Image source, int width, int height) {
    final sourceRatio = source.width / source.height;
    final targetRatio = width / height;
    int cropX = 0;
    int cropY = 0;
    int cropWidth = source.width;
    int cropHeight = source.height;

    if (sourceRatio > targetRatio) {
      cropWidth = (source.height * targetRatio).round();
      cropX = ((source.width - cropWidth) / 2).round();
    } else {
      cropHeight = (source.width / targetRatio).round();
      cropY = ((source.height - cropHeight) / 2).round();
    }

    final cropped = img.copyCrop(
      source,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );
    return img.copyResize(
      cropped,
      width: width,
      height: height,
      interpolation: img.Interpolation.cubic,
    );
  }

  static void _roundCorners(img.Image image, int radius) {
    final radiusSquared = radius * radius;
    for (final pixel in image) {
      final left = pixel.x < radius;
      final right = pixel.x >= image.width - radius;
      final top = pixel.y < radius;
      final bottom = pixel.y >= image.height - radius;
      if ((!left && !right) || (!top && !bottom)) {
        continue;
      }

      final cx = left ? radius : image.width - radius - 1;
      final cy = top ? radius : image.height - radius - 1;
      final dx = pixel.x - cx;
      final dy = pixel.y - cy;
      final distanceSquared = dx * dx + dy * dy;
      if (distanceSquared > radiusSquared) {
        pixel.a = 0;
      } else if (distanceSquared > radiusSquared - radius * 2) {
        final distance = math.sqrt(distanceSquared);
        final alpha = ((radius - distance).clamp(0, 1) * 255).round();
        pixel.a = alpha;
      }
    }
  }

  static void _drawLeicaLogo(
    img.Image canvas,
    int centerX,
    int centerY,
    int radius,
  ) {
    img.fillCircle(
      canvas,
      x: centerX,
      y: centerY,
      radius: radius,
      color: _rgb(229, 0, 18),
      antialias: true,
    );
    final label = radius > 30 ? 'Leica' : 'L';
    final font = radius > 30 ? img.arial24 : img.arial14;
    img.drawString(
      canvas,
      label,
      font: font,
      x: centerX - _textWidth(font, label) ~/ 2,
      y: centerY - (radius > 30 ? 12 : 7),
      color: _rgb(255, 255, 255),
    );
  }

  static int _textWidth(img.BitmapFont font, String value) {
    var width = 0;
    for (final code in value.codeUnits) {
      width += font.characterXAdvance(String.fromCharCode(code));
    }
    return width;
  }

  static String _truncateAscii(String value, int maxChars) {
    final sanitized = value.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
    if (sanitized.length <= maxChars) {
      return sanitized;
    }
    return '${sanitized.substring(0, math.max(0, maxChars - 3))}...';
  }

  static img.ColorRgb8 _rgb(int r, int g, int b) => img.ColorRgb8(r, g, b);

  static img.ColorRgba8 _rgba(int r, int g, int b, int a) =>
      img.ColorRgba8(r, g, b, a);
}
