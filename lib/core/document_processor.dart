import 'dart:typed_data';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class DocumentProcessor {
  static const double _maxDeskewAngle = 45;
  static const int _minNonZeroPoints = 500;
  static const double _minSkewDegrees = 1.0;

  static Uint8List autoEnhance(Uint8List imageBytes) {
    final src = cv.imdecode(imageBytes, cv.IMREAD_COLOR);
    if (src.rows == 0 || src.cols == 0) {
      throw Exception('Failed to decode image');
    }

    final gray = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
    final result = _deskew(gray);
    final color = cv.cvtColor(result, cv.COLOR_GRAY2BGR);
    final (success, encoded) = cv.imencode(
      '.jpg',
      color,
      params: cv.VecI32.fromList([cv.IMWRITE_JPEG_QUALITY, 92]),
    );
    if (!success) throw Exception('Failed to encode enhanced image');
    return encoded;
  }

  static cv.Mat _deskew(cv.Mat gray) {
    final (_, binary) = cv.threshold(gray, 0, 255, cv.THRESH_BINARY | cv.THRESH_OTSU);
    final nz = cv.findNonZero(binary);
    if (nz.total < _minNonZeroPoints) return gray;

    final points = cv.VecPoint.fromMat(nz);
    final rect = cv.minAreaRect(points);
    var angle = rect.angle;

    if (rect.size.width < rect.size.height) {
      angle = 90 + angle;
    }

    if (angle.abs() < _minSkewDegrees || angle.abs() > _maxDeskewAngle) {
      return gray;
    }

    final center = cv.Point2f(gray.cols / 2.0, gray.rows / 2.0);
    final rotMat = cv.getRotationMatrix2D(center, angle, 1.0);
    return cv.warpAffine(
      gray,
      rotMat,
      (gray.cols, gray.rows),
      flags: cv.INTER_CUBIC,
      borderMode: cv.BORDER_REPLICATE,
    );
  }
}
