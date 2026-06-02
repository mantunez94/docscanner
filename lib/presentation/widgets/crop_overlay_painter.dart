import 'package:flutter/material.dart';

class CropOverlayPainter extends CustomPainter {
  final List<Offset>? corners;
  final Rect imageRect;
  final bool fullOverlay;

  CropOverlayPainter({
    required this.corners,
    required this.imageRect,
    this.fullOverlay = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (corners == null || corners!.length < 4) {
      final paint = Paint()
        ..color = Colors.cyan.withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      final rect = Rect.fromCenter(
        center: imageRect.center,
        width: imageRect.width * 0.8,
        height: imageRect.height * 0.8,
      );
      canvas.drawRect(rect, paint);
      return;
    }

    final cropPath = Path()
      ..moveTo(corners![0].dx, corners![0].dy)
      ..lineTo(corners![1].dx, corners![1].dy)
      ..lineTo(corners![2].dx, corners![2].dy)
      ..lineTo(corners![3].dx, corners![3].dy)
      ..close();

    if (fullOverlay) {
      final overlayPaint = Paint()
        ..color = Colors.black.withAlpha(100);
      final path = Path()..addRect(Offset.zero & size);
      path.addPath(cropPath, Offset.zero);
      canvas.drawPath(path, overlayPaint);
    }

    final linePaint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(cropPath, linePaint);

    final gridPaint = Paint()
      ..color = Colors.white.withAlpha(40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (var i = 1; i < 10; i++) {
      final t = i / 10;
      final top = Offset.lerp(corners![0], corners![3], t)!;
      final bottom = Offset.lerp(corners![1], corners![2], t)!;
      canvas.drawLine(top, bottom, gridPaint);

      final left = Offset.lerp(corners![0], corners![1], t)!;
      final right = Offset.lerp(corners![3], corners![2], t)!;
      canvas.drawLine(left, right, gridPaint);
    }
  }

  @override
  bool shouldRepaint(CropOverlayPainter old) =>
      old.corners != corners || old.fullOverlay != fullOverlay;
}
