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
    final (_, binary) = cv.threshold(gray, 0, 255, cv.THRESH_BINARY | cv.THRESH_OTSU);
    final denoised = cv.medianBlur(binary, 3);
    final result = _deskew(denoised);

    final (success, encoded) = cv.imencode('.jpg', result);
    if (!success) throw Exception('Failed to encode enhanced image');
    return encoded;
  }

  static cv.Mat _deskew(cv.Mat binary) {
    final nz = cv.findNonZero(binary);
    if (nz.total < _minNonZeroPoints) return binary;

    final points = cv.VecPoint.fromMat(nz);
    final rect = cv.minAreaRect(points);
    var angle = rect.angle;

    if (rect.size.width < rect.size.height) {
      angle = 90 + angle;
    }

    if (angle.abs() < _minSkewDegrees || angle.abs() > _maxDeskewAngle) {
      return binary;
    }

    final center = cv.Point2f(binary.cols / 2.0, binary.rows / 2.0);
    final rotMat = cv.getRotationMatrix2D(center, angle, 1.0);
    return cv.warpAffine(
      binary,
      rotMat,
      (binary.cols, binary.rows),
      flags: cv.INTER_CUBIC,
      borderMode: cv.BORDER_REPLICATE,
    );
  }
}
