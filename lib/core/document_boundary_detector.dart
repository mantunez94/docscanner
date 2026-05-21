import 'dart:math' as math;
import 'dart:typed_data';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class DocumentBoundaryDetector {
  static const double _targetWidth = 320;
  static const double _cannyLow = 50;
  static const double _cannyHigh = 150;
  static const double _minAreaFraction = 0.08;
  static const double _maxAreaFraction = 0.95;
  static const double _epsilonFactor = 0.02;

  List<cv.Point>? detectBoundary(
    Uint8List yPlane,
    int imageWidth,
    int imageHeight, {
    int? stride,
  }) {
    final s = stride ?? imageWidth;

    final scale = _targetWidth / imageWidth;
    final dstW = _targetWidth.round();
    final dstH = (imageHeight * scale).round();
    if (dstH <= 0) return null;

    final downsampled = _downsample(yPlane, s, imageWidth, imageHeight, dstW, dstH);
    final gray = cv.Mat.fromList(dstH, dstW, cv.MatType.CV_8UC1, downsampled.toList());

    final blurred = cv.gaussianBlur(gray, (5, 5), 0);
    final edges = cv.canny(blurred, _cannyLow, _cannyHigh);
    final (contours, _) = cv.findContours(edges, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);

    cv.VecPoint? bestContour;
    var bestArea = 0.0;
    final totalArea = dstW * dstH;

    for (var i = 0; i < contours.length; i++) {
      final contour = contours[i];
      final area = cv.contourArea(contour);
      if (area < _minAreaFraction * totalArea || area > _maxAreaFraction * totalArea) continue;

      final perimeter = cv.arcLength(contour, true);
      if (perimeter <= 0) continue;

      final approx = cv.approxPolyDP(contour, _epsilonFactor * perimeter, true);
      if (approx.length >= 4 && approx.length <= 6) {
        if (area > bestArea) {
          bestArea = area;
          bestContour = approx;
        }
      }
    }

    if (bestContour == null || bestContour.length < 4) return null;

    final invScale = 1.0 / scale;
    final pts = <cv.Point>[];
    for (var i = 0; i < bestContour.length; i++) {
      pts.add(bestContour[i]);
    }

    if (pts.length > 4) {
      final cx = pts.map((p) => p.x).reduce((a, b) => a + b) / pts.length;
      final cy = pts.map((p) => p.y).reduce((a, b) => a + b) / pts.length;
      pts.sort((a, b) {
        final da = math.atan2(a.y - cy, a.x - cx);
        final db = math.atan2(b.y - cy, b.x - cx);
        return da.compareTo(db);
      });
      while (pts.length > 4) pts.removeLast();
    }

    final cx = pts.map((p) => p.x).reduce((a, b) => a + b) / pts.length;
    final cy = pts.map((p) => p.y).reduce((a, b) => a + b) / pts.length;

    final sorted = [...pts];
    sorted.sort((a, b) {
      final da = math.atan2(a.y - cy, a.x - cx);
      final db = math.atan2(b.y - cy, b.x - cx);
      return da.compareTo(db);
    });

    final topLeftAngle = math.atan2(sorted[0].y - cy, sorted[0].x - cx);
    final minAngleIdx = topLeftAngle > 0
        ? sorted.indexWhere((p) => math.atan2(p.y - cy, p.x - cx) < 0)
        : -1;

    if (minAngleIdx > 0) {
      final reordered = [...sorted.sublist(minAngleIdx), ...sorted.sublist(0, minAngleIdx)];
      return reordered.map((p) => cv.Point(
        (p.x * invScale).round(),
        (p.y * invScale).round(),
      )).toList();
    }

    return sorted.map((p) => cv.Point(
      (p.x * invScale).round(),
      (p.y * invScale).round(),
    )).toList();
  }

  double computeAreaFraction(List<cv.Point> corners, int imageWidth, int imageHeight) {
    if (corners.length < 4) return 0;
    double area = 0;
    for (var i = 0; i < 4; i++) {
      final j = (i + 1) % 4;
      area += corners[i].x * corners[j].y;
      area -= corners[j].x * corners[i].y;
    }
    return area.abs() / (2 * imageWidth * imageHeight);
  }

  Uint8List _downsample(
    Uint8List src,
    int srcStride,
    int srcW,
    int srcH,
    int dstW,
    int dstH,
  ) {
    final dst = Uint8List(dstW * dstH);
    for (var y = 0; y < dstH; y++) {
      final srcY = (y * srcH ~/ dstH).clamp(0, srcH - 1);
      final dstRow = y * dstW;
      final srcRow = srcY * srcStride;
      for (var x = 0; x < dstW; x++) {
        final srcX = (x * srcW ~/ dstW).clamp(0, srcStride - 1);
        dst[dstRow + x] = src[srcRow + srcX];
      }
    }
    return dst;
  }
}
