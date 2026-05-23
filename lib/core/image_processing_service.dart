import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class ImageProcessingService {
  List<cv.Point>? detectDocumentFromMat(cv.Mat src) {
    try {
      if (src.rows == 0 || src.cols == 0) return null;
      final scale = 320.0 / src.cols;
      final dstW = 320;
      final dstH = (src.rows * scale).round();
      if (dstH <= 0) return null;

      final small = cv.resize(src, (dstW, dstH));
      final gray = cv.cvtColor(small, cv.COLOR_BGR2GRAY);
      final totalArea = dstW * dstH;

      final clahe = cv.CLAHE.create(2.0, (8, 8));
      final equalized = clahe.apply(gray);
      final blurred = cv.gaussianBlur(equalized, (5, 5), 0);
      final (_, binary) = cv.threshold(blurred, 0, 255, cv.THRESH_BINARY | cv.THRESH_OTSU);

      final kernel = cv.getStructuringElement(cv.MORPH_RECT, (5, 5));
      final closed = cv.morphologyEx(binary, cv.MORPH_CLOSE, kernel, iterations: 2);
      final opened = cv.morphologyEx(closed, cv.MORPH_OPEN, kernel, iterations: 1);

      final (contours, _) = cv.findContours(opened, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);

      double bestArea = 0;
      cv.VecPoint? bestContour;
      for (var i = 0; i < contours.length; i++) {
        final area = cv.contourArea(contours[i]);
        if (area < 0.03 * totalArea || area > 0.97 * totalArea) continue;
        if (area > bestArea) {
          bestArea = area;
          bestContour = contours[i];
        }
      }

      if (bestContour == null) {
        final mean2 = cv.mean(gray).val1;
        double cLow, cHigh;
        if (mean2 < 50) {
          cLow = 20; cHigh = 60;
        } else if (mean2 < 100) {
          cLow = 30; cHigh = 100;
        } else {
          cLow = 50; cHigh = 150;
        }
        final edges = cv.canny(blurred, cLow, cHigh);
        final dKernel = cv.getStructuringElement(cv.MORPH_RECT, (3, 3));
        final dilated = cv.dilate(edges, dKernel, iterations: 3);
        final (edgeContours, _) = cv.findContours(dilated, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);

        for (var i = 0; i < edgeContours.length; i++) {
          final area = cv.contourArea(edgeContours[i]);
          if (area < 0.03 * totalArea || area > 0.97 * totalArea) continue;
          if (area > bestArea) {
            bestArea = area;
            bestContour = edgeContours[i];
          }
        }
      }

      if (bestContour != null) {
        final rect = cv.minAreaRect(bestContour);
        final box = rect.points;
        final invScale = 1.0 / scale;
        final corners = <cv.Point>[];
        for (var i = 0; i < box.length; i++) {
          final p = box[i];
          corners.add(cv.Point(
            (p.x * invScale).round(),
            (p.y * invScale).round(),
          ));
        }
        return orderCorners(corners);
      }
    } catch (_) {}
    return null;
  }

  cv.Mat enhanceScan(cv.Mat bgr, {bool colorMode = false}) {
    if (colorMode) {
      final adjusted = cv.convertScaleAbs(bgr, alpha: 1.1, beta: 5);
      final kernel = cv.Mat.fromList(3, 3, cv.MatType.CV_32FC1, [
        0.0, -1.0, 0.0,
        -1.0, 5.0, -1.0,
        0.0, -1.0, 0.0,
      ]);
      return cv.filter2D(adjusted, -1, kernel);
    }
    final gray = cv.cvtColor(bgr, cv.COLOR_BGR2GRAY);
    cv.normalize(gray, gray, alpha: 0, beta: 255, normType: cv.NORM_MINMAX);
    final adjusted = cv.convertScaleAbs(gray, alpha: 1.25, beta: 5);
    final kernel = cv.Mat.fromList(3, 3, cv.MatType.CV_32FC1, [
      0.0, -1.0, 0.0,
      -1.0, 5.0, -1.0,
      0.0, -1.0, 0.0,
    ]);
    final sharpened = cv.filter2D(adjusted, -1, kernel);
    return cv.cvtColor(sharpened, cv.COLOR_GRAY2BGR);
  }

  List<cv.Point> orderCorners(List<cv.Point> pts) {
    final cx = pts.map((p) => p.x).reduce((a, b) => a + b) / pts.length;
    final cy = pts.map((p) => p.y).reduce((a, b) => a + b) / pts.length;
    pts.sort((a, b) {
      final da = math.atan2(a.y - cy, a.x - cx);
      final db = math.atan2(b.y - cy, b.x - cx);
      return da.compareTo(db);
    });
    final topLeftAngle = math.atan2(pts[0].y - cy, pts[0].x - cx);
    final idx = topLeftAngle > 0
        ? pts.indexWhere((p) => math.atan2(p.y - cy, p.x - cx) < 0)
        : -1;
    if (idx > 0) return [...pts.sublist(idx), ...pts.sublist(0, idx)];
    return pts;
  }

  List<cv.Point> applyDragToCorners(
    List<cv.Point> corners,
    int index,
    Offset delta,
    double scaleX,
    double scaleY,
    int imgW,
    int imgH,
  ) {
    final dx = (delta.dx / scaleX).round();
    final dy = (delta.dy / scaleY).round();
    final updated = List<cv.Point>.from(corners);
    updated[index] = cv.Point(
      (updated[index].x + dx).clamp(0, imgW - 1),
      (updated[index].y + dy).clamp(0, imgH - 1),
    );
    return updated;
  }

  (Uint8List image, cv.Mat mat) decodeImage(String path) {
    final bytes = File(path).readAsBytesSync();
    final mat = cv.imdecode(bytes, cv.IMREAD_COLOR);
    return (bytes, mat);
  }

  (Uint8List encoded, cv.Mat processed) processScan(
    Uint8List bytes,
    List<cv.Point>? corners,
    bool colorMode,
  ) {
    final src = cv.imdecode(bytes, cv.IMREAD_COLOR);
    if (src.rows == 0 || src.cols == 0) {
      throw Exception('Failed to decode image');
    }

    if (corners != null && corners.length >= 4) {
      final tl = corners[0];
      final tr = corners[1];
      final br = corners[2];
      final bl = corners[3];

      final dstW = ((tr.x - tl.x + br.x - bl.x) / 2).abs().round();
      final dstH = ((bl.y - tl.y + br.y - tr.y) / 2).abs().round();
      if (dstW > 0 && dstH > 0) {
        final srcPts = cv.VecPoint2f();
        srcPts.add(cv.Point2f(tl.x.toDouble(), tl.y.toDouble()));
        srcPts.add(cv.Point2f(tr.x.toDouble(), tr.y.toDouble()));
        srcPts.add(cv.Point2f(br.x.toDouble(), br.y.toDouble()));
        srcPts.add(cv.Point2f(bl.x.toDouble(), bl.y.toDouble()));

        final dstPts = cv.VecPoint2f();
        dstPts.add(cv.Point2f(0, 0));
        dstPts.add(cv.Point2f((dstW - 1).toDouble(), 0));
        dstPts.add(cv.Point2f((dstW - 1).toDouble(), (dstH - 1).toDouble()));
        dstPts.add(cv.Point2f(0, (dstH - 1).toDouble()));

        final M = cv.getPerspectiveTransform2f(srcPts, dstPts);
        final warped = cv.warpPerspective(src, M, (dstW, dstH));
        final enhanced = enhanceScan(warped, colorMode: colorMode);

        final (success, encoded) = cv.imencode(
          '.jpg',
          enhanced,
          params: cv.VecI32.fromList([cv.IMWRITE_JPEG_QUALITY, 92]),
        );
        if (!success) throw Exception('Failed to encode image');
        return (encoded, enhanced);
      }
    }

    final (success, encoded) = cv.imencode(
      '.jpg',
      src,
      params: cv.VecI32.fromList([cv.IMWRITE_JPEG_QUALITY, 92]),
    );
    if (!success) throw Exception('Failed to encode image');
    return (encoded, src);
  }
}
