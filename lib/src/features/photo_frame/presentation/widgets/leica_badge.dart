import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../../domain/leica_badge_path.dart';

class LeicaBadge extends StatelessWidget {
  const LeicaBadge({
    required this.size,
    this.color = const Color(0xFFE50012),
    super.key,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _LeicaBadgePainter(color)),
    );
  }
}

class _LeicaBadgePainter extends CustomPainter {
  _LeicaBadgePainter(this.color);

  static final Path _path = parseSvgPathData(leicaBadgeSvgPathData);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final offset = Offset((size.width - side) / 2, (size.height - side) / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final cutoutPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas
      ..save()
      ..translate(offset.dx, offset.dy)
      ..scale(side / leicaBadgeViewBoxSize)
      ..drawCircle(const Offset(12, 12), 11.75, cutoutPaint)
      ..drawPath(_path, paint)
      ..restore();
  }

  @override
  bool shouldRepaint(_LeicaBadgePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
