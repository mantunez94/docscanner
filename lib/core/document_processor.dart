import 'package:image/image.dart' as img;

enum DocumentFilter { original, grayscale, blackAndWhite, enhanced }

class DocumentProcessor {
  static img.Image applyFilter(img.Image image, DocumentFilter filter) {
    switch (filter) {
      case DocumentFilter.original:
        return image;
      case DocumentFilter.grayscale:
        return img.grayscale(image);
      case DocumentFilter.blackAndWhite:
        final gray = img.grayscale(image);
        return _threshold(gray, 128);
      case DocumentFilter.enhanced:
        var result = img.grayscale(image);
        result = img.adjustColor(result, contrast: 1.4);
        result = img.gaussianBlur(result, radius: 1);
        return result;
    }
  }

  static img.Image _threshold(img.Image image, int threshold) {
    final result = img.Image.from(image);
    for (var y = 0; y < result.height; y++) {
      for (var x = 0; x < result.width; x++) {
        final pixel = result.getPixel(x, y);
        if (pixel.luminance > threshold) {
          result.setPixelRgba(x, y, 255, 255, 255, 255);
        } else {
          result.setPixelRgba(x, y, 0, 0, 0, 255);
        }
      }
    }
    return result;
  }
}
