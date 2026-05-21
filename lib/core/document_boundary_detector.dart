import 'dart:math' as math;
import 'dart:typed_data';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class DocumentBoundaryDetector {
  static const double _targetWidth = 320;
  static const double _minAreaFraction = 0.03;
  static const double _maxAreaFraction = 0.97;

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

    final result = _findDocumentContour(gray);
    if (result != null) {
      final invScale = 1.0 / scale;
      return result.map((p) => cv.Point(
        (p.x * invScale).round(),
        (p.y * invScale).round(),
      )).toList();
    }

    return null;
  }

  List<cv.Point>? _findDocumentContour(cv.Mat gray) {
    final totalArea = gray.cols * gray.rows;

    try {
      final blurred = cv.gaussianBlur(gray, (5, 5), 0);
      final (_, binary) = cv.threshold(blurred, 0, 255, cv.THRESH_BINARY | cv.THRESH_OTSU);

      final kernel = cv.getStructuringElement(cv.MORPH_RECT, (5, 5));
      final closed = cv.morphologyEx(binary, cv.MORPH_CLOSE, kernel, iterations: 3);
      final cleaned = cv.morphologyEx(closed, cv.MORPH_OPEN, kernel, iterations: 2);

      final (contours, _) = cv.findContours(cleaned, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);
      final quad = _bestQuadFromContours(contours, totalArea);
      if (quad != null) return quad;
    } catch (_) {}

    try {
      final blurred = cv.gaussianBlur(gray, (5, 5), 0);
      final edges = cv.canny(blurred, 30, 100);
      final kernel = cv.getStructuringElement(cv.MORPH_RECT, (3, 3));
      final dilated = cv.dilate(edges, kernel, iterations: 3);

      final (contours, _) = cv.findContours(dilated, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);
      final quad = _bestQuadFromContours(contours, totalArea);
      if (quad != null) return quad;
    } catch (_) {}

    return null;
  }

  List<cv.Point>? _bestQuadFromContours(cv.VecVecPoint contours, int totalArea) {
    double bestArea = 0;
    cv.VecPoint? bestContour;

    for (var i = 0; i < contours.length; i++) {
      final contour = contours[i];
      final area = cv.contourArea(contour);
      if (area < _minAreaFraction * totalArea || area > _maxAreaFraction * totalArea) continue;
      if (area > bestArea) {
        bestArea = area;
        bestContour = contour;
      }
    }

    if (bestContour == null) return null;

    try {
      final rect = cv.minAreaRect(bestContour);
      final box = rect.points;

      final corners = <cv.Point>[];
      for (var i = 0; i < box.length; i++) {
        final p = box[i];
        corners.add(cv.Point(p.x.round(), p.y.round()));
      }

      final area2 = _computePolygonArea(corners);
      if (area2 >= _minAreaFraction * totalArea && area2 <= _maxAreaFraction * totalArea) {
        return _sortClockwise(corners);
      }
    } catch (_) {}

    return null;
  }

  List<cv.Point> _sortClockwise(List<cv.Point> pts) {
    if (pts.isEmpty) return pts;

    final cx = pts.map((p) => p.x).reduce((a, b) => a + b) / pts.length;
    final cy = pts.map((p) => p.y).reduce((a, b) => a + b) / pts.length;

    pts.sort((a, b) {
      final da = math.atan2(a.y - cy, a.x - cx);
      final db = math.atan2(b.y - cy, b.x - cx);
      return da.compareTo(db);
    });

    if (pts.length <= 4) {
      final topLeftAngle = math.atan2(pts[0].y - cy, pts[0].x - cx);
      final minAngleIdx = topLeftAngle > 0
          ? pts.indexWhere((p) => math.atan2(p.y - cy, p.x - cx) < 0)
          : -1;
      if (minAngleIdx > 0) {
        return [...pts.sublist(minAngleIdx), ...pts.sublist(0, minAngleIdx)];
      }
      return pts;
    }

    while (pts.length > 4) pts.removeLast();
    return pts;
  }

  double _computePolygonArea(List<cv.Point> corners) {
    double area = 0;
    for (var i = 0; i < corners.length; i++) {
      final j = (i + 1) % corners.length;
      area += corners[i].x * corners[j].y;
      area -= corners[j].x * corners[i].y;
    }
    return area.abs() / 2;
  }

  double computeAreaFraction(List<cv.Point> corners, int imageWidth, int imageHeight) {
    if (corners.length < 4) return 0;
    return _computePolygonArea(corners) / (imageWidth * imageHeight);
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
