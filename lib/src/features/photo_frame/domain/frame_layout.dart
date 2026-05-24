import 'dart:math' as math;

import 'frame_options.dart';

class FrameLayoutMetrics {
  const FrameLayoutMetrics({
    required this.canvasWidth,
    required this.canvasHeight,
    required this.photoX,
    required this.photoY,
    required this.photoWidth,
    required this.photoHeight,
    required this.cornerRadius,
    required this.infoY,
    required this.infoHeight,
    required this.marginX,
    required this.logoSize,
    required this.logoCenterX,
    required this.logoCenterY,
    required this.logoTextGap,
    required this.primaryFontSize,
    required this.secondaryFontSize,
    required this.lineGap,
  });

  final int canvasWidth;
  final int canvasHeight;
  final int photoX;
  final int photoY;
  final int photoWidth;
  final int photoHeight;
  final int cornerRadius;
  final int infoY;
  final int infoHeight;
  final int marginX;
  final int logoSize;
  final int logoCenterX;
  final int logoCenterY;
  final int logoTextGap;
  final int primaryFontSize;
  final int secondaryFontSize;
  final int lineGap;

  double get aspectRatio => canvasWidth / canvasHeight;

  int get photoRight => photoX + photoWidth;
  int get photoBottom => photoY + photoHeight;
  int get primaryTextY {
    final textHeight = primaryFontSize + lineGap + secondaryFontSize;
    return logoCenterY - textHeight ~/ 2;
  }

  int get secondaryTextY => primaryTextY + primaryFontSize + lineGap;

  static FrameLayoutMetrics softGlow({
    required int photoWidth,
    required int photoHeight,
    required FrameOptions options,
  }) {
    final borderScale = options.normalizedBorderScale;
    final logoScale = options.normalizedLogoScale;
    final textScale = options.normalizedTextScale;
    final sidePadding = _scaledFromPhoto(72 * borderScale, photoWidth);
    final topPadding = _scaledFromPhoto(72 * borderScale, photoWidth);
    final logoSize = _scaledFromPhoto(48 * logoScale, photoWidth);
    final primaryFontSize = _scaledFromPhoto(24 * textScale, photoWidth);
    final bottomPadding = math.max(
      _scaledFromPhoto(170 * borderScale, photoWidth),
      math.max(logoSize, primaryFontSize) +
          _scaledFromPhoto(82 * borderScale, photoWidth),
    );
    final canvasWidth = photoWidth + sidePadding * 2;
    final canvasHeight = topPadding + photoHeight + bottomPadding;
    final infoY = topPadding + photoHeight;
    return FrameLayoutMetrics(
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
      photoX: sidePadding,
      photoY: topPadding,
      photoWidth: photoWidth,
      photoHeight: photoHeight,
      cornerRadius: _scaledFromPhoto(28 * borderScale, photoWidth),
      infoY: infoY,
      infoHeight: bottomPadding,
      marginX: sidePadding,
      logoSize: logoSize,
      logoCenterX: canvasWidth ~/ 2,
      logoCenterY: infoY + bottomPadding ~/ 2,
      logoTextGap: _scaledFromPhoto(24, photoWidth),
      primaryFontSize: primaryFontSize,
      secondaryFontSize: primaryFontSize,
      lineGap: _scaledFromPhoto(12, photoWidth),
    );
  }

  static FrameLayoutMetrics whiteInfo({
    required int photoWidth,
    required int photoHeight,
    required FrameOptions options,
  }) {
    final borderScale = options.normalizedBorderScale;
    final logoScale = options.normalizedLogoScale;
    final textScale = options.normalizedTextScale;
    final canvasWidth = photoWidth;
    final logoSize = _scaled(72 * logoScale, canvasWidth);
    final primaryFontSize = _scaled(24 * textScale, canvasWidth);
    final secondaryFontSize = _scaled(14 * textScale, canvasWidth);
    final lineGap = _scaled(20 * textScale, canvasWidth);
    final textHeight = primaryFontSize + lineGap + secondaryFontSize;
    final infoHeight = math.max(
      _scaled(210 * borderScale, canvasWidth),
      math.max(logoSize, textHeight) + _scaled(76 * borderScale, canvasWidth),
    );
    final marginX = _scaled(80 * borderScale, canvasWidth);
    final logoCenterX = switch (options.badgeAlignment) {
      LeicaBadgeAlignment.left => marginX + logoSize ~/ 2,
      LeicaBadgeAlignment.center => canvasWidth ~/ 2,
      LeicaBadgeAlignment.right => canvasWidth - marginX - logoSize ~/ 2,
    };
    return FrameLayoutMetrics(
      canvasWidth: canvasWidth,
      canvasHeight: photoHeight + infoHeight,
      photoX: 0,
      photoY: 0,
      photoWidth: photoWidth,
      photoHeight: photoHeight,
      cornerRadius: 0,
      infoY: photoHeight,
      infoHeight: infoHeight,
      marginX: marginX,
      logoSize: logoSize,
      logoCenterX: logoCenterX,
      logoCenterY: photoHeight + infoHeight ~/ 2,
      logoTextGap: _scaled(112, canvasWidth),
      primaryFontSize: primaryFontSize,
      secondaryFontSize: secondaryFontSize,
      lineGap: lineGap,
    );
  }

  static int _scaled(num value, int canvasWidth) {
    return math.max(1, (value * canvasWidth / 1440).round());
  }

  static int _scaledFromPhoto(num value, int photoWidth) {
    return math.max(1, (value * photoWidth / 1296).round());
  }
}
