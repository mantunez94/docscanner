import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:docscanner/presentation/screens/preview_screen.dart';

void main() {
  group('applyDragToCorners', () {
    final initialCorners = [
      cv.Point(100, 100),
      cv.Point(400, 100),
      cv.Point(400, 600),
      cv.Point(100, 600),
    ];

    test('only the dragged corner changes', () {
      const index = 0;
      const delta = Offset(20, 15);
      const scaleX = 0.5;
      const scaleY = 0.5;
      const imgW = 500;
      const imgH = 700;

      final result = applyDragToCorners(
        initialCorners, index, delta, scaleX, scaleY, imgW, imgH,
      );

      expect(result[0].x, 140);
      expect(result[0].y, 130);
      expect(result[1].x, 400);
      expect(result[1].y, 100);
      expect(result[2].x, 400);
      expect(result[2].y, 600);
      expect(result[3].x, 100);
      expect(result[3].y, 600);
    });

    test('dragging each corner independently', () {
      const imgW = 500;
      const imgH = 700;
      const scaleX = 1.0;
      const scaleY = 1.0;
      const delta = Offset(10, 10);

      for (var i = 0; i < 4; i++) {
        final result = applyDragToCorners(
          initialCorners, i, delta, scaleX, scaleY, imgW, imgH,
        );

        expect(result[i].x, initialCorners[i].x + 10);
        expect(result[i].y, initialCorners[i].y + 10);

        for (var j = 0; j < 4; j++) {
          if (j != i) {
            expect(result[j].x, initialCorners[j].x);
            expect(result[j].y, initialCorners[j].y);
          }
        }
      }
    });

    test('corner position is clamped within image bounds', () {
      const index = 0;
      const imgW = 500;
      const imgH = 700;
      const scaleX = 1.0;
      const scaleY = 1.0;

      final result = applyDragToCorners(
        initialCorners, index, const Offset(-500, 600),
        scaleX, scaleY, imgW, imgH,
      );

      expect(result[0].x, 0);
      expect(result[0].y, imgH - 1);
    });

    test('does not mutate original list', () {
      const index = 1;
      const imgW = 500;
      const imgH = 700;
      const delta = Offset(10, 10);
      const scaleX = 1.0;
      const scaleY = 1.0;

      final originalCopy = initialCorners.map((p) => cv.Point(p.x, p.y)).toList();
      applyDragToCorners(initialCorners, index, delta, scaleX, scaleY, imgW, imgH);

      for (var i = 0; i < 4; i++) {
        expect(initialCorners[i].x, originalCopy[i].x);
        expect(initialCorners[i].y, originalCopy[i].y);
      }
    });
  });
}
