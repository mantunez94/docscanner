import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class MagnifierPainter extends CustomPainter {
  final ui.Image image;
  final double focalX;
  final double focalY;
  final double zoom;
  final double imgW;
  final double imgH;

  MagnifierPainter({
    required this.image,
    required this.focalX,
    required this.focalY,
    required this.zoom,
    required this.imgW,
    required this.imgH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final halfW = size.width / (2 * zoom);
    final halfH = size.height / (2 * zoom);
    final srcRect = Rect.fromLTWH(
      (focalX - halfW).clamp(0, imgW - 1),
      (focalY - halfH).clamp(0, imgH - 1),
      (halfW * 2).clamp(1, imgW),
      (halfH * 2).clamp(1, imgH),
    );
    canvas.drawImageRect(image, srcRect, Offset.zero & size, Paint());
  }

  @override
  bool shouldRepaint(MagnifierPainter old) =>
      old.focalX != focalX || old.focalY != focalY || old.zoom != zoom;
}
