import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../domain/frame_layout.dart';
import '../domain/frame_options.dart';
import '../domain/frame_style.dart';
import '../domain/photo_asset.dart';
import 'leica_badge_png.dart';

class FrameRenderer {
  const FrameRenderer._();

  static Future<Uint8List> render(
    PhotoAsset photo,
    FrameStyle style, {
    FrameOptions options = const FrameOptions(),
  }) {
    final logoBytes = LeicaBadgePng.bytesForSize(72);
    return compute(_renderOnIsolate, <String, Object?>{
      'bytes': photo.bytes,
      'name': photo.name,
      'style': style.name,
      'options': options.toMap(),
      'exif': photo.exif.toMap(),
      'logoBytes': logoBytes,
    });
  }

  static Uint8List _renderOnIsolate(Map<String, Object?> payload) {
    final bytes = payload['bytes']! as Uint8List;
    final name = payload['name']! as String;
    final style = FrameStyle.values.byName(payload['style']! as String);
    final options = FrameOptions.fromMap(
      Map<String, Object?>.from(payload['options']! as Map),
    );
    final exifMap = Map<String, Object?>.from(payload['exif']! as Map);
    final exif = PhotoExif.fromMap(exifMap);
    final logo = img.decodePng(payload['logoBytes']! as Uint8List);
    if (logo == null) {
      throw StateError('无法读取徕卡图标');
    }
    final decoded = _decodeSourceImage(name, bytes);
    if (decoded == null) {
      throw StateError('Unsupported image format: $name');
    }
    final source = img.bakeOrientation(decoded);
    final output = switch (style) {
      FrameStyle.softGlow => _renderSoftGlow(source, exif, logo, options),
      FrameStyle.whiteInfo => _renderWhiteInfo(source, exif, logo, options),
    };
    return img.encodePng(output, level: 1, filter: img.PngFilter.none);
  }

  static img.Image _renderSoftGlow(
    img.Image source,
    PhotoExif exif,
    img.Image logoBadge,
    FrameOptions options,
  ) {
    final layout = FrameLayoutMetrics.softGlow(
      photoWidth: source.width,
      photoHeight: source.height,
      options: options,
    );

    final background = _blurredCover(
      source,
      layout.canvasWidth,
      layout.canvasHeight,
    );
    img.fillRect(
      background,
      x1: 0,
      y1: 0,
      x2: layout.canvasWidth - 1,
      y2: layout.canvasHeight - 1,
      color: _rgba(12, 18, 14, 116),
    );

    _drawSoftShadow(
      background,
      x1: layout.photoX + 10,
      y1: layout.photoY + 24,
      x2: layout.photoRight - 10,
      y2: layout.photoBottom + 36,
      radius: layout.cornerRadius,
    );
    _compositeRoundedPhoto(
      background,
      source,
      dstX: layout.photoX,
      dstY: layout.photoY,
      radius: layout.cornerRadius,
    );

    final text = options.softInfoLine(exif);
    final maxTextWidth = math.max(
      0,
      layout.canvasWidth -
          layout.marginX * 2 -
          layout.logoSize -
          layout.logoTextGap,
    );
    final safeText = _truncateAsciiToScaledWidth(
      text,
      layout.primaryFontSize,
      maxTextWidth,
    );
    final textWidth = _scaledTextWidth(safeText, layout.primaryFontSize);
    final groupWidth =
        layout.logoSize +
        (safeText.isEmpty ? 0 : layout.logoTextGap + textWidth);
    final startX = switch (options.badgeAlignment) {
      LeicaBadgeAlignment.left => layout.marginX,
      LeicaBadgeAlignment.center =>
        ((layout.canvasWidth - groupWidth) / 2).round(),
      LeicaBadgeAlignment.right =>
        layout.canvasWidth - layout.marginX - groupWidth,
    };
    if (options.badgeAlignment == LeicaBadgeAlignment.right &&
        safeText.isNotEmpty) {
      _drawScaledString(
        background,
        safeText,
        fontSize: layout.primaryFontSize,
        x: startX,
        y: layout.logoCenterY - layout.primaryFontSize ~/ 2,
        color: _rgb(244, 247, 242),
      );
      _drawLeicaLogo(
        background,
        logoBadge,
        startX + textWidth + layout.logoTextGap + layout.logoSize ~/ 2,
        layout.logoCenterY,
        layout.logoSize,
      );
    } else {
      _drawLeicaLogo(
        background,
        logoBadge,
        startX + layout.logoSize ~/ 2,
        layout.logoCenterY,
        layout.logoSize,
      );
      if (safeText.isNotEmpty) {
        _drawScaledString(
          background,
          safeText,
          fontSize: layout.primaryFontSize,
          x: startX + layout.logoSize + layout.logoTextGap,
          y: layout.logoCenterY - layout.primaryFontSize ~/ 2,
          color: _rgb(244, 247, 242),
        );
      }
    }

    return background;
  }

  static img.Image _renderWhiteInfo(
    img.Image source,
    PhotoExif exif,
    img.Image logoBadge,
    FrameOptions options,
  ) {
    final layout = FrameLayoutMetrics.whiteInfo(
      photoWidth: source.width,
      photoHeight: source.height,
      options: options,
    );
    final canvas = img.Image(
      width: layout.canvasWidth,
      height: layout.canvasHeight,
    );
    img.fill(canvas, color: _rgb(255, 255, 255));

    img.compositeImage(canvas, source);

    img.fillRect(
      canvas,
      x1: 0,
      y1: layout.infoY,
      x2: layout.canvasWidth - 1,
      y2: layout.canvasHeight - 1,
      color: _rgb(250, 250, 249),
    );
    img.drawLine(
      canvas,
      x1: 0,
      y1: layout.infoY,
      x2: layout.canvasWidth - 1,
      y2: layout.infoY,
      color: _rgb(228, 230, 234),
    );

    _drawLeicaLogo(
      canvas,
      logoBadge,
      layout.logoCenterX,
      layout.logoCenterY,
      layout.logoSize,
    );

    if (options.badgeAlignment == LeicaBadgeAlignment.center) {
      final logoOffset = layout.logoSize ~/ 2 + layout.logoTextGap;
      final leftMaxWidth = layout.logoCenterX - logoOffset - layout.marginX;
      final rightX = layout.logoCenterX + logoOffset;
      final rightMaxWidth = layout.canvasWidth - layout.marginX - rightX;
      _drawInfoBlock(
        canvas,
        primary: options.cameraInfoLine(exif),
        secondary: options.dateInfoLine(exif),
        x: layout.marginX,
        maxWidth: leftMaxWidth,
        layout: layout,
      );
      _drawInfoBlock(
        canvas,
        primary: options.exposureInfoLine(exif),
        secondary: options.locationInfoLine(exif),
        x: rightX,
        maxWidth: rightMaxWidth,
        layout: layout,
      );
    } else if (options.badgeAlignment == LeicaBadgeAlignment.left) {
      final x = layout.logoCenterX + layout.logoSize ~/ 2 + layout.logoTextGap;
      _drawInfoBlock(
        canvas,
        primary: options.combinedPrimaryInfoLine(exif),
        secondary: options.combinedSecondaryInfoLine(exif),
        x: x,
        maxWidth: layout.canvasWidth - layout.marginX - x,
        layout: layout,
      );
    } else {
      final maxWidth =
          layout.logoCenterX -
          layout.logoSize ~/ 2 -
          layout.logoTextGap -
          layout.marginX;
      _drawInfoBlock(
        canvas,
        primary: options.combinedPrimaryInfoLine(exif),
        secondary: options.combinedSecondaryInfoLine(exif),
        x: layout.marginX,
        maxWidth: maxWidth,
        layout: layout,
      );
    }

    return canvas;
  }

  static img.Image _coverResize(
    img.Image source,
    int width,
    int height, {
    img.Interpolation interpolation = img.Interpolation.linear,
  }) {
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
      interpolation: interpolation,
    );
  }

  static img.Image? _decodeSourceImage(String name, Uint8List bytes) {
    try {
      return img.decodeNamedImage(name, bytes) ?? img.decodeImage(bytes);
    } catch (_) {
      return img.decodeImage(bytes);
    }
  }

  static img.Image _blurredCover(img.Image source, int width, int height) {
    const maxBlurSide = 720;
    final largestSide = math.max(width, height);
    final scale = math.max(1, (largestSide / maxBlurSide).ceil());
    final smallWidth = math.max(1, width ~/ scale);
    final smallHeight = math.max(1, height ~/ scale);
    final small = _coverResize(
      source,
      smallWidth,
      smallHeight,
      interpolation: img.Interpolation.linear,
    );
    final blurred = _fastBoxBlur(
      small,
      radius: math.max(2, (math.min(smallWidth, smallHeight) / 56).round()),
      passes: 2,
    );
    return img.copyResize(
      blurred,
      width: width,
      height: height,
      interpolation: img.Interpolation.linear,
    );
  }

  static img.Image _fastBoxBlur(
    img.Image source, {
    required int radius,
    required int passes,
  }) {
    final minSide = math.min(source.width, source.height);
    if (minSide < 3 || radius <= 0 || passes <= 0) {
      return source;
    }
    final safeRadius = math.min(radius, math.max(1, minSide ~/ 3));
    final rgbaSource = source.numChannels == 4
        ? source
        : source.convert(numChannels: 4);
    var current = Uint8List.fromList(
      rgbaSource.getBytes(order: img.ChannelOrder.rgba),
    );
    var scratch = Uint8List(current.length);
    for (var pass = 0; pass < passes; pass++) {
      _boxBlurHorizontal(
        current,
        scratch,
        source.width,
        source.height,
        safeRadius,
      );
      _boxBlurVertical(
        scratch,
        current,
        source.width,
        source.height,
        safeRadius,
      );
    }
    return img.Image.fromBytes(
      width: source.width,
      height: source.height,
      bytes: current.buffer,
      bytesOffset: current.offsetInBytes,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
  }

  static void _boxBlurHorizontal(
    Uint8List source,
    Uint8List target,
    int width,
    int height,
    int radius,
  ) {
    final window = radius * 2 + 1;
    final lastX = width - 1;
    for (var y = 0; y < height; y++) {
      final rowOffset = y * width * 4;
      var red = 0;
      var green = 0;
      var blue = 0;
      var alpha = 0;
      for (var x = -radius; x <= radius; x++) {
        final offset = rowOffset + _clampIndex(x, lastX) * 4;
        red += source[offset];
        green += source[offset + 1];
        blue += source[offset + 2];
        alpha += source[offset + 3];
      }
      for (var x = 0; x < width; x++) {
        final offset = rowOffset + x * 4;
        target[offset] = red ~/ window;
        target[offset + 1] = green ~/ window;
        target[offset + 2] = blue ~/ window;
        target[offset + 3] = alpha ~/ window;

        final removeOffset = rowOffset + _clampIndex(x - radius, lastX) * 4;
        final addOffset = rowOffset + _clampIndex(x + radius + 1, lastX) * 4;
        red += source[addOffset] - source[removeOffset];
        green += source[addOffset + 1] - source[removeOffset + 1];
        blue += source[addOffset + 2] - source[removeOffset + 2];
        alpha += source[addOffset + 3] - source[removeOffset + 3];
      }
    }
  }

  static void _boxBlurVertical(
    Uint8List source,
    Uint8List target,
    int width,
    int height,
    int radius,
  ) {
    final window = radius * 2 + 1;
    final lastY = height - 1;
    for (var x = 0; x < width; x++) {
      final columnOffset = x * 4;
      var red = 0;
      var green = 0;
      var blue = 0;
      var alpha = 0;
      for (var y = -radius; y <= radius; y++) {
        final offset = (_clampIndex(y, lastY) * width * 4) + columnOffset;
        red += source[offset];
        green += source[offset + 1];
        blue += source[offset + 2];
        alpha += source[offset + 3];
      }
      for (var y = 0; y < height; y++) {
        final offset = y * width * 4 + columnOffset;
        target[offset] = red ~/ window;
        target[offset + 1] = green ~/ window;
        target[offset + 2] = blue ~/ window;
        target[offset + 3] = alpha ~/ window;

        final removeOffset =
            (_clampIndex(y - radius, lastY) * width * 4) + columnOffset;
        final addOffset =
            (_clampIndex(y + radius + 1, lastY) * width * 4) + columnOffset;
        red += source[addOffset] - source[removeOffset];
        green += source[addOffset + 1] - source[removeOffset + 1];
        blue += source[addOffset + 2] - source[removeOffset + 2];
        alpha += source[addOffset + 3] - source[removeOffset + 3];
      }
    }
  }

  static int _clampIndex(int value, int max) {
    if (value < 0) {
      return 0;
    }
    if (value > max) {
      return max;
    }
    return value;
  }

  static void _drawSoftShadow(
    img.Image canvas, {
    required int x1,
    required int y1,
    required int x2,
    required int y2,
    required int radius,
  }) {
    const blurRadius = 24;
    const scale = 4;
    const blurPadding = blurRadius * 3;
    final regionX = math.max(0, x1 - blurPadding);
    final regionY = math.max(0, y1 - blurPadding);
    final regionRight = math.min(canvas.width - 1, x2 + blurPadding);
    final regionBottom = math.min(canvas.height - 1, y2 + blurPadding);
    final regionWidth = regionRight - regionX + 1;
    final regionHeight = regionBottom - regionY + 1;
    final smallWidth = math.max(1, regionWidth ~/ scale);
    final smallHeight = math.max(1, regionHeight ~/ scale);
    final smallShadow = img.Image(
      width: smallWidth,
      height: smallHeight,
      numChannels: 4,
    );
    img.fill(smallShadow, color: _rgba(0, 0, 0, 0));
    img.fillRect(
      smallShadow,
      x1: ((x1 - regionX) / scale).round(),
      y1: ((y1 - regionY) / scale).round(),
      x2: ((x2 - regionX) / scale).round(),
      y2: ((y2 - regionY) / scale).round(),
      color: _rgba(0, 0, 0, 126),
      radius: math.max(1, radius ~/ scale),
    );
    _gaussianBlurSafe(smallShadow, radius: math.max(1, blurRadius ~/ scale));
    final shadow = img.copyResize(
      smallShadow,
      width: regionWidth,
      height: regionHeight,
      interpolation: img.Interpolation.cubic,
    );
    img.compositeImage(canvas, shadow, dstX: regionX, dstY: regionY);
  }

  static void _compositeRoundedPhoto(
    img.Image canvas,
    img.Image source, {
    required int dstX,
    required int dstY,
    required int radius,
  }) {
    final cornerRadius = math.min(
      radius,
      math.max(1, math.min(source.width, source.height) ~/ 2),
    );
    final topLeft = img.copyCrop(
      canvas,
      x: dstX,
      y: dstY,
      width: cornerRadius,
      height: cornerRadius,
    );
    final topRight = img.copyCrop(
      canvas,
      x: dstX + source.width - cornerRadius,
      y: dstY,
      width: cornerRadius,
      height: cornerRadius,
    );
    final bottomLeft = img.copyCrop(
      canvas,
      x: dstX,
      y: dstY + source.height - cornerRadius,
      width: cornerRadius,
      height: cornerRadius,
    );
    final bottomRight = img.copyCrop(
      canvas,
      x: dstX + source.width - cornerRadius,
      y: dstY + source.height - cornerRadius,
      width: cornerRadius,
      height: cornerRadius,
    );

    img.compositeImage(canvas, source, dstX: dstX, dstY: dstY);

    _restoreRoundedCorner(
      canvas,
      topLeft,
      originX: dstX,
      originY: dstY,
      centerX: dstX + cornerRadius,
      centerY: dstY + cornerRadius,
      radius: cornerRadius,
    );
    _restoreRoundedCorner(
      canvas,
      topRight,
      originX: dstX + source.width - cornerRadius,
      originY: dstY,
      centerX: dstX + source.width - cornerRadius - 1,
      centerY: dstY + cornerRadius,
      radius: cornerRadius,
    );
    _restoreRoundedCorner(
      canvas,
      bottomLeft,
      originX: dstX,
      originY: dstY + source.height - cornerRadius,
      centerX: dstX + cornerRadius,
      centerY: dstY + source.height - cornerRadius - 1,
      radius: cornerRadius,
    );
    _restoreRoundedCorner(
      canvas,
      bottomRight,
      originX: dstX + source.width - cornerRadius,
      originY: dstY + source.height - cornerRadius,
      centerX: dstX + source.width - cornerRadius - 1,
      centerY: dstY + source.height - cornerRadius - 1,
      radius: cornerRadius,
    );
  }

  static void _restoreRoundedCorner(
    img.Image canvas,
    img.Image backgroundPatch, {
    required int originX,
    required int originY,
    required int centerX,
    required int centerY,
    required int radius,
  }) {
    final radiusSquared = radius * radius;
    final antialiasStart = radiusSquared - radius * 2;
    for (var localY = 0; localY < radius; localY++) {
      final y = originY + localY;
      for (var localX = 0; localX < radius; localX++) {
        final x = originX + localX;
        final dx = x - centerX;
        final dy = y - centerY;
        final distanceSquared = dx * dx + dy * dy;
        if (distanceSquared <= antialiasStart) {
          continue;
        }

        final backgroundPixel = backgroundPatch.getPixel(localX, localY);
        if (distanceSquared > radiusSquared) {
          canvas.setPixelRgba(
            x,
            y,
            backgroundPixel.r,
            backgroundPixel.g,
            backgroundPixel.b,
            backgroundPixel.a,
          );
          continue;
        }

        final distance = math.sqrt(distanceSquared);
        final alpha = ((radius - distance).clamp(0, 1) * 255).round();
        final sourcePixel = canvas.getPixel(x, y);
        final inverseAlpha = 255 - alpha;
        canvas.setPixelRgba(
          x,
          y,
          (sourcePixel.r * alpha + backgroundPixel.r * inverseAlpha) ~/ 255,
          (sourcePixel.g * alpha + backgroundPixel.g * inverseAlpha) ~/ 255,
          (sourcePixel.b * alpha + backgroundPixel.b * inverseAlpha) ~/ 255,
          255,
        );
      }
    }
  }

  static void _gaussianBlurSafe(img.Image image, {required int radius}) {
    final minSide = math.min(image.width, image.height);
    if (minSide < 3) {
      return;
    }
    final safeRadius = math.min(radius, math.max(1, minSide ~/ 3));
    img.gaussianBlur(image, radius: safeRadius);
  }

  static void _drawLeicaLogo(
    img.Image canvas,
    img.Image logoBadge,
    int centerX,
    int centerY,
    int size,
  ) {
    final badge = logoBadge.width == size && logoBadge.height == size
        ? logoBadge
        : img.copyResize(
            logoBadge,
            width: size,
            height: size,
            interpolation: img.Interpolation.cubic,
          );
    img.compositeImage(
      canvas,
      badge,
      dstX: centerX - size ~/ 2,
      dstY: centerY - size ~/ 2,
    );
  }

  static void _drawInfoBlock(
    img.Image canvas, {
    required String primary,
    required String secondary,
    required int x,
    required int maxWidth,
    required FrameLayoutMetrics layout,
  }) {
    if (maxWidth <= 0) {
      return;
    }
    final primaryText = _truncateAsciiToScaledWidth(
      primary,
      layout.primaryFontSize,
      maxWidth,
    );
    final secondaryText = _truncateAsciiToScaledWidth(
      secondary,
      layout.secondaryFontSize,
      maxWidth,
    );
    if (primaryText.isNotEmpty) {
      _drawScaledString(
        canvas,
        primaryText,
        fontSize: layout.primaryFontSize,
        x: x,
        y: layout.primaryTextY,
        color: _rgb(16, 18, 22),
      );
    }
    if (secondaryText.isNotEmpty) {
      _drawScaledString(
        canvas,
        secondaryText,
        fontSize: layout.secondaryFontSize,
        x: x,
        y: primaryText.isEmpty
            ? layout.logoCenterY - layout.secondaryFontSize ~/ 2
            : layout.secondaryTextY,
        color: _rgb(120, 124, 130),
      );
    }
  }

  static void _drawScaledString(
    img.Image canvas,
    String value, {
    required int fontSize,
    required int x,
    required int y,
    required img.Color color,
  }) {
    final text = _sanitizeAscii(value);
    if (text.isEmpty) {
      return;
    }
    final font = _fontForSize(fontSize);
    final nativeSize = _fontNativeSize(font);
    final scale = fontSize / nativeSize;
    final rawWidth = _textWidth(font, text);
    final rawHeight = math.max(font.lineHeight, nativeSize);
    if (rawWidth <= 0 || rawHeight <= 0) {
      return;
    }
    final textImage = img.Image(
      width: rawWidth + 2,
      height: rawHeight + 2,
      numChannels: 4,
    );
    img.fill(textImage, color: _rgba(0, 0, 0, 0));
    img.drawString(textImage, text, font: font, x: 0, y: 0, color: color);

    final rendered = (scale - 1).abs() < 0.02
        ? textImage
        : img.copyResize(
            textImage,
            width: math.max(1, (textImage.width * scale).round()),
            height: math.max(1, (textImage.height * scale).round()),
            interpolation: img.Interpolation.linear,
          );
    img.compositeImage(canvas, rendered, dstX: x, dstY: y);
  }

  static int _textWidth(img.BitmapFont font, String value) {
    var width = 0;
    for (final code in value.codeUnits) {
      width += font.characterXAdvance(String.fromCharCode(code));
    }
    return width;
  }

  static int _scaledTextWidth(String value, int fontSize) {
    final text = _sanitizeAscii(value);
    if (text.isEmpty) {
      return 0;
    }
    final font = _fontForSize(fontSize);
    final scale = fontSize / _fontNativeSize(font);
    return (_textWidth(font, text) * scale).ceil();
  }

  static String _truncateAsciiToScaledWidth(
    String value,
    int fontSize,
    int maxWidth,
  ) {
    if (maxWidth <= 0) {
      return '';
    }
    final sanitized = _sanitizeAscii(value);
    if (sanitized.isEmpty) {
      return '';
    }
    final font = _fontForSize(fontSize);
    final scale = fontSize / _fontNativeSize(font);
    if (_textWidth(font, sanitized) * scale <= maxWidth) {
      return sanitized;
    }
    const ellipsis = '...';
    final ellipsisWidth = _textWidth(font, ellipsis) * scale;
    if (ellipsisWidth > maxWidth) {
      return '';
    }
    final buffer = StringBuffer();
    var width = 0.0;
    for (final code in sanitized.codeUnits) {
      final char = String.fromCharCode(code);
      final nextWidth = font.characterXAdvance(char) * scale;
      if (width + nextWidth + ellipsisWidth > maxWidth) {
        break;
      }
      buffer.writeCharCode(code);
      width += nextWidth;
    }
    final prefix = buffer.toString().trimRight();
    if (prefix.isEmpty) {
      return ellipsis;
    }
    return '$prefix$ellipsis';
  }

  static String _sanitizeAscii(String value) {
    return value.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim();
  }

  static img.BitmapFont _fontForSize(int fontSize) {
    if (fontSize <= 18) {
      return img.arial14;
    }
    if (fontSize <= 36) {
      return img.arial24;
    }
    return img.arial48;
  }

  static int _fontNativeSize(img.BitmapFont font) {
    if (identical(font, img.arial48)) {
      return 48;
    }
    if (identical(font, img.arial24)) {
      return 24;
    }
    return 14;
  }

  static img.ColorRgb8 _rgb(int r, int g, int b) => img.ColorRgb8(r, g, b);

  static img.ColorRgba8 _rgba(int r, int g, int b, int a) =>
      img.ColorRgba8(r, g, b, a);
}
