import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class BoundaryOverlayPainter extends CustomPainter {
  final List<cv.Point>? corners;
  final double previewWidth;
  final double previewHeight;
  final double previewOffsetX;
  final double previewOffsetY;
  final double previewPaintWidth;
  final double previewPaintHeight;
  final int sensorOrientation;
  final int imageWidth;
  final int imageHeight;

  const BoundaryOverlayPainter({
    this.corners,
    required this.previewWidth,
    required this.previewHeight,
    required this.previewOffsetX,
    required this.previewOffsetY,
    required this.previewPaintWidth,
    required this.previewPaintHeight,
    required this.sensorOrientation,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withAlpha(100)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final cornerPaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.fill;

    if (corners != null && corners!.length >= 4) {
      final pts = _mapCorners(corners!);

      final docPath = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (var i = 1; i < pts.length; i++) {
        docPath.lineTo(pts[i].dx, pts[i].dy);
      }
      docPath.close();

      canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
          docPath,
        ),
        paint,
      );

      canvas.drawPath(docPath, borderPaint);

      for (final p in pts) {
        canvas.drawCircle(p, 6, cornerPaint);
        canvas.drawCircle(p, 6, Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
      }
    } else {
      final centerX = previewOffsetX + previewPaintWidth / 2;
      final centerY = previewOffsetY + previewPaintHeight / 2;

      final rect = Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: previewPaintWidth * 0.85,
        height: previewPaintHeight * 0.55,
      );

      canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
          Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12))),
        ),
        paint,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(12)),
        borderPaint,
      );
    }
  }

  List<Offset> _mapCorners(List<cv.Point> corners) {
    return corners.map((p) {
      double x = p.x.toDouble();
      double y = p.y.toDouble();

      final w = imageWidth.toDouble();
      final h = imageHeight.toDouble();

      switch (sensorOrientation) {
        case 90:
          final tmp = x;
          x = h - y;
          y = tmp;
        case 180:
          x = w - x;
          y = h - y;
        case 270:
          final tmp = x;
          x = y;
          y = w - tmp;
      }

      final displayW = (sensorOrientation == 90 || sensorOrientation == 270) ? h : w;
      final displayH = (sensorOrientation == 90 || sensorOrientation == 270) ? w : h;

      return Offset(
        previewOffsetX + x * previewPaintWidth / displayW,
        previewOffsetY + y * previewPaintHeight / displayH,
      );
    }).toList();
  }

  @override
  bool shouldRepaint(covariant BoundaryOverlayPainter oldDelegate) {
    return oldDelegate.corners != corners ||
        oldDelegate.previewOffsetX != previewOffsetX ||
        oldDelegate.previewOffsetY != previewOffsetY ||
        oldDelegate.previewPaintWidth != previewPaintWidth ||
        oldDelegate.previewPaintHeight != previewPaintHeight;
  }
}
