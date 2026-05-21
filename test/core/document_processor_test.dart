import 'package:docscanner/core/document_processor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  group('DocumentProcessor', () {
    late img.Image testImage;

    setUp(() {
      testImage = img.Image(width: 4, height: 4);
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 4; x++) {
          final bright = (x + y) % 2 == 0;
          testImage.setPixelRgba(
            x, y,
            bright ? 200 : 50,
            bright ? 200 : 50,
            bright ? 200 : 50,
            255,
          );
        }
      }
    });

    test('applyFilter with original returns same image', () {
      final result = DocumentProcessor.applyFilter(testImage, DocumentFilter.original);
      expect(result.width, testImage.width);
      expect(result.height, testImage.height);
      expect(result.getPixel(0, 0).r, 200);
      expect(result.getPixel(0, 0).g, 200);
      expect(result.getPixel(0, 0).b, 200);
    });

    test('applyFilter with grayscale produces gray pixels', () {
      final result = DocumentProcessor.applyFilter(testImage, DocumentFilter.grayscale);
      for (var y = 0; y < result.height; y++) {
        for (var x = 0; x < result.width; x++) {
          final p = result.getPixel(x, y);
          expect(p.r, p.g);
          expect(p.g, p.b);
        }
      }
    });

    test('applyFilter with blackAndWhite produces only black or white pixels', () {
      final result = DocumentProcessor.applyFilter(testImage, DocumentFilter.blackAndWhite);
      for (var y = 0; y < result.height; y++) {
        for (var x = 0; x < result.width; x++) {
          final p = result.getPixel(x, y);
          final isBlack = p.r == 0 && p.g == 0 && p.b == 0;
          final isWhite = p.r == 255 && p.g == 255 && p.b == 255;
          expect(isBlack || isWhite, isTrue);
        }
      }
    });

    test('applyFilter with enhanced produces grayscale image', () {
      final result = DocumentProcessor.applyFilter(testImage, DocumentFilter.enhanced);
      for (var y = 0; y < result.height; y++) {
        for (var x = 0; x < result.width; x++) {
          final p = result.getPixel(x, y);
          expect(p.r, p.g);
          expect(p.g, p.b);
        }
      }
    });

    test('applyFilter does not change image dimensions', () {
      final original = DocumentProcessor.applyFilter(testImage, DocumentFilter.original);
      final grayscale = DocumentProcessor.applyFilter(testImage, DocumentFilter.grayscale);
      final bw = DocumentProcessor.applyFilter(testImage, DocumentFilter.blackAndWhite);
      final enhanced = DocumentProcessor.applyFilter(testImage, DocumentFilter.enhanced);

      expect(original.width, 4);
      expect(original.height, 4);
      expect(grayscale.width, 4);
      expect(grayscale.height, 4);
      expect(bw.width, 4);
      expect(bw.height, 4);
      expect(enhanced.width, 4);
      expect(enhanced.height, 4);
    });
  });
}
