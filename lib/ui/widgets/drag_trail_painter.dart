import 'package:flutter/material.dart';

class DragTrailPainter extends CustomPainter {
  final List<Offset> points;
  final Color trailColor;
  final double strokeWidth;

  DragTrailPainter({
    required this.points,
    required this.trailColor,
    this.strokeWidth = 14.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final outerPaint = Paint()
      ..color = trailColor.withOpacity(0.4)
      ..strokeWidth = strokeWidth * 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final innerPaint = Paint()
      ..color = trailColor.withOpacity(0.85)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final corePaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = strokeWidth * 0.35
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, outerPaint);
    canvas.drawPath(path, innerPaint);
    canvas.drawPath(path, corePaint);
  }

  @override
  bool shouldRepaint(covariant DragTrailPainter oldDelegate) {
    return oldDelegate.points.length != points.length || oldDelegate.trailColor != trailColor;
  }
}
