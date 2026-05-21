import 'dart:typed_data';
import 'package:docscanner/core/document_processor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  group('DocumentProcessor', () {
    late img.Image testImage;

    setUp(() {
      testImage = img.Image(width: 8, height: 8);
      for (var y = 0; y < 8; y++) {
        for (var x = 0; x < 8; x++) {
          final bright = (x + y) % 2 == 0;
          testImage.setPixelRgba(
            x, y,
            bright ? 220 : 40,
            bright ? 220 : 40,
            bright ? 220 : 40,
            255,
          );
        }
      }
    });

    test('autoEnhance produces valid JPG bytes', () {
      final inputBytes = Uint8List.fromList(img.encodeJpg(testImage, quality: 90));
      final result = DocumentProcessor.autoEnhance(inputBytes);
      expect(result.length, greaterThan(0));
      final decoded = img.decodeJpg(result);
      expect(decoded, isNotNull);
    }, skip: 'Requires native OpenCV library (libdartcv.so)');

    test('autoEnhance returns different bytes than input', () {
      final inputBytes = Uint8List.fromList(img.encodeJpg(testImage, quality: 90));
      final result = DocumentProcessor.autoEnhance(inputBytes);
      expect(result, isNot(equals(inputBytes)));
    }, skip: 'Requires native OpenCV library (libdartcv.so)');

    test('autoEnhance preserves image dimensions', () {
      final inputBytes = Uint8List.fromList(img.encodeJpg(testImage, quality: 90));
      final result = DocumentProcessor.autoEnhance(inputBytes);
      final decoded = img.decodeJpg(result)!;
      expect(decoded.width, 8);
      expect(decoded.height, 8);
    }, skip: 'Requires native OpenCV library (libdartcv.so)');

    test('autoEnhance throws on invalid input', () {
      final invalidBytes = Uint8List.fromList([0, 1, 2, 3, 4, 5]);
      expect(
        () => DocumentProcessor.autoEnhance(invalidBytes),
        throwsException,
      );
    }, skip: 'Requires native OpenCV library (libdartcv.so)');
  });
}
