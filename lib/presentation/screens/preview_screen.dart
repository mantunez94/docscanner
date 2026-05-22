import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import '../../domain/entities/ocr_result.dart';
import '../providers/ocr_provider.dart';

class PreviewScreen extends ConsumerStatefulWidget {
  final String imagePath;

  const PreviewScreen({super.key, required this.imagePath});

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  Uint8List? _displayBytes;
  bool _ocrLoading = false;
  bool _saving = false;
  List<cv.Point>? _corners;
  List<cv.Point>? _originalCorners;
  int _imgW = 0;
  int _imgH = 0;
  Rect _imageRect = Rect.zero;
  int _draggingIndex = -1;
  Offset _dragLocalPos = Offset.zero;
  final _stackKey = GlobalKey();
  cv.Mat? _imageMat;
  ui.Image? _uiImage;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    if (!mounted) return;
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    _uiImage = frame.image;
    _imageMat = cv.imdecode(bytes, cv.IMREAD_COLOR);
    final src = _imageMat!;
    _imgW = src.cols;
    _imgH = src.rows;
    _corners = _detectDocumentFromMat(src);
    if (_corners == null && _imgW > 0 && _imgH > 0) {
      final m = 0.1;
      _corners = [
        cv.Point((_imgW * m).round(), (_imgH * m).round()),
        cv.Point((_imgW * (1 - m)).round(), (_imgH * m).round()),
        cv.Point((_imgW * (1 - m)).round(), (_imgH * (1 - m)).round()),
        cv.Point((_imgW * m).round(), (_imgH * (1 - m)).round()),
      ];
    }
    setState(() {
      _displayBytes = bytes;
      _originalCorners = _corners != null ? List<cv.Point>.from(_corners!) : null;
    });
  }

  List<cv.Point>? _detectDocumentFromMat(cv.Mat src) {
    try {
      if (src.rows == 0 || src.cols == 0) return null;
      final scale = 320.0 / src.cols;
      final dstW = 320;
      final dstH = (src.rows * scale).round();
      if (dstH <= 0) return null;

      final small = cv.resize(src, (dstW, dstH));
      final gray = cv.cvtColor(small, cv.COLOR_BGR2GRAY);
      final totalArea = dstW * dstH;

      final blurred = cv.gaussianBlur(gray, (5, 5), 0);
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
        final edges = cv.canny(blurred, 50, 150);
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
        return _orderCorners(corners);
      }
    } catch (_) {}
    return null;
  }

  cv.Mat _enhanceScan(cv.Mat bgr) {
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

  List<cv.Point> _orderCorners(List<cv.Point> pts) {
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

  Offset _imageToScreen(cv.Point p) {
    if (_imageRect.isEmpty || _imgW == 0 || _imgH == 0) return Offset.zero;
    final scaleX = _imageRect.width / _imgW;
    final scaleY = _imageRect.height / _imgH;
    return Offset(
      _imageRect.left + p.x * scaleX,
      _imageRect.top + p.y * scaleY,
    );
  }

  void _onHandleDragStart(int index, DragStartDetails details) {
    setState(() => _draggingIndex = index);
    _updateDragPos(details.globalPosition);
  }

  void _onHandleDragUpdate(int index, DragUpdateDetails details) {
    _onHandleDrag(index, details.delta);
    _updateDragPos(details.globalPosition);
  }

  void _onHandleDragEnd(_) {
    setState(() => _draggingIndex = -1);
  }

  void _updateDragPos(Offset globalPos) {
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      _dragLocalPos = box.globalToLocal(globalPos);
    }
  }

  void _onHandleDrag(int index, Offset delta) {
    if (_corners == null || _imageRect.isEmpty || _imgW == 0 || _imgH == 0) return;
    final scaleX = _imageRect.width / _imgW;
    final scaleY = _imageRect.height / _imgH;
    final updated = applyDragToCorners(_corners!, index, delta, scaleX, scaleY, _imgW, _imgH);
    setState(() => _corners = updated);
  }

  Future<void> _runOcr() async {
    setState(() => _ocrLoading = true);
    try {
      final service = ref.read(ocrServiceProvider);
      final result = await service.recognizeImage(widget.imagePath);
      if (!mounted) return;
      setState(() => _ocrLoading = false);
      _showOcrResult(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _ocrLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Text extraction failed. Please try again.')),
      );
    }
  }

  void _showOcrResult(OcrResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.2,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Extracted Text', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('${result.blocks.length} text blocks found',
                      style: Theme.of(context).textTheme.bodySmall),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        SelectableText(result.text,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await _copyToClipboard(result.text);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy to Clipboard'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Text copied to clipboard')),
      );
    }
  }

  bool get _hasChanges {
    if (_originalCorners == null || _corners == null) return false;
    if (_originalCorners!.length != _corners!.length) return true;
    for (var i = 0; i < _originalCorners!.length; i++) {
      if (_originalCorners![i].x != _corners![i].x ||
          _originalCorners![i].y != _corners![i].y) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_displayBytes == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Preview')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text('You have made adjustments to the crop area. Do you want to discard them?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep editing'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        );
        if (confirm == true && mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
      appBar: AppBar(title: const Text('Adjust & Confirm')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_imgW > 0 && _imgH > 0) {
            final scale = math.min(
              constraints.maxWidth / _imgW,
              constraints.maxHeight / _imgH,
            );
            final rW = _imgW * scale;
            final rH = _imgH * scale;
            _imageRect = Rect.fromLTWH(
              (constraints.maxWidth - rW) / 2,
              (constraints.maxHeight - rH) / 2,
              rW,
              rH,
            );
          }
          const mgSize = 200.0;
          const mgGap = 30.0;
          final mgLeft = _draggingIndex >= 0 && _uiImage != null && _corners != null
              ? (_dragLocalPos.dx - mgSize / 2).clamp(0, constraints.maxWidth - mgSize).toDouble()
              : 0.0;
          final mgTop = _draggingIndex >= 0 && _uiImage != null && _corners != null
              ? (_dragLocalPos.dy < constraints.maxHeight * 0.4
                  ? (_dragLocalPos.dy + mgGap).clamp(0, constraints.maxHeight - mgSize).toDouble()
                  : (_dragLocalPos.dy - mgSize - mgGap).clamp(0, constraints.maxHeight - mgSize).toDouble())
              : 0.0;

          return Stack(
            key: _stackKey,
            children: [
              Center(
                child: Image.memory(_displayBytes!, fit: BoxFit.contain, semanticLabel: 'Document preview'),
              ),
              if (_imageRect != Rect.zero)
                Positioned.fill(
                  child: Semantics(
                    label: 'Crop region overlay',
                    excludeSemantics: true,
                    child: CustomPaint(
                    painter: _CropOverlayPainter(
                      corners: _corners?.map(_imageToScreen).toList(),
                      imageRect: _imageRect,
                      fullOverlay: _draggingIndex < 0,
                    ),
                  ),
                  ),
                ),
              if (_corners != null && _imageRect != Rect.zero)
                for (var i = 0; i < _corners!.length; i++)
                  Positioned(
                    left: _imageToScreen(_corners![i]).dx - 24,
                    top: _imageToScreen(_corners![i]).dy - 24,
                    child: Semantics(
                      label: 'Crop corner ${i + 1}',
                      child: GestureDetector(
                        onPanStart: (d) => _onHandleDragStart(i, d),
                        onPanUpdate: (d) => _onHandleDragUpdate(i, d),
                        onPanEnd: _onHandleDragEnd,
                        child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _draggingIndex == i
                              ? Colors.cyan.withAlpha(80)
                              : Colors.cyan,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: Icon(
                          _draggingIndex == i ? Icons.circle : Icons.drag_handle,
                          color: Colors.white, size: 16,
                        ),
                      ),
                    ),
                    ),
                  ),
              if (_draggingIndex >= 0 && _uiImage != null && _corners != null)
                Positioned(
                  left: mgLeft,
                  top: mgTop,
                  child: IgnorePointer(
                    child: Container(
                      width: mgSize,
                      height: mgSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(blurRadius: 16, color: Colors.black45),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                  child: Semantics(
                    label: 'Magnified view of corner region',
                    excludeSemantics: true,
                    child: CustomPaint(
                      painter: _MagnifierPainter(
                          image: _uiImage!,
                          focalX: _corners![_draggingIndex].x.toDouble(),
                          focalY: _corners![_draggingIndex].y.toDouble(),
                          zoom: 4.0,
                          imgW: _imgW.toDouble(),
                          imgH: _imgH.toDouble(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ],
            );
          },
        ),
        bottomNavigationBar: Container(
        color: Colors.black87,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Tooltip(
                message: 'Reset corners',
                child: IconButton(
                  onPressed: _originalCorners != null
                      ? () => setState(() => _corners = List<cv.Point>.from(_originalCorners!))
                      : null,
                  icon: const Icon(Icons.crop_square, color: Colors.white, size: 26),
                ),
              ),
              Tooltip(
                message: 'Extract text from this page',
                child: IconButton(
                  onPressed: _ocrLoading ? null : _runOcr,
                  icon: _ocrLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.text_snippet, color: Colors.white, size: 26),
                ),
              ),
              Tooltip(
                message: 'Take photo again',
                child: IconButton(
                  onPressed: () => Navigator.pop(context, 'retake'),
                  icon: const Icon(Icons.camera_alt, color: Colors.white, size: 26),
                ),
              ),
              Tooltip(
                message: 'Save scan',
                child: IconButton(
                  icon: _saving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle, color: Colors.white, size: 30),
                  onPressed: _saving ? null : _onConfirm,
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  void _onConfirm() {
    setState(() => _saving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _processScan());
  }

  Future<void> _processScan() async {
    try {
      final bytes = _displayBytes;
      if (bytes == null) throw Exception('No image');

      final src = cv.imdecode(bytes, cv.IMREAD_COLOR);
      if (src.rows == 0 || src.cols == 0) throw Exception('Failed to decode');

      final corners = _corners;
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
          final enhanced = _enhanceScan(warped);

          final (success, encoded) = cv.imencode(
            '.jpg',
            enhanced,
            params: cv.VecI32.fromList([cv.IMWRITE_JPEG_QUALITY, 92]),
          );
          if (!success) throw Exception('Failed to encode');
          if (mounted) Navigator.pop(context, encoded);
          return;
        }
      }

      final (success, encoded) = cv.imencode(
        '.jpg',
        src,
        params: cv.VecI32.fromList([cv.IMWRITE_JPEG_QUALITY, 92]),
      );
      if (!success) throw Exception('Failed to encode');
      if (mounted) Navigator.pop(context, encoded);
    } catch (e) {
      if (mounted) {
        final bytes = _displayBytes;
        if (bytes != null) {
          Navigator.pop(context, bytes);
        } else {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to process image. Please try again.')),
          );
        }
      } else {
        _saving = false;
      }
    }
  }
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

class _CropOverlayPainter extends CustomPainter {
  final List<Offset>? corners;
  final Rect imageRect;
  final bool fullOverlay;

  _CropOverlayPainter({
    required this.corners,
    required this.imageRect,
    this.fullOverlay = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (corners == null || corners!.length < 4) {
      final paint = Paint()
        ..color = Colors.cyan.withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      final rect = Rect.fromCenter(
        center: imageRect.center,
        width: imageRect.width * 0.8,
        height: imageRect.height * 0.8,
      );
      canvas.drawRect(rect, paint);
      return;
    }

    final cropPath = Path()
      ..moveTo(corners![0].dx, corners![0].dy)
      ..lineTo(corners![1].dx, corners![1].dy)
      ..lineTo(corners![2].dx, corners![2].dy)
      ..lineTo(corners![3].dx, corners![3].dy)
      ..close();

    if (fullOverlay) {
      final overlayPaint = Paint()
        ..color = Colors.black.withAlpha(100);
      final path = Path()..addRect(Offset.zero & size);
      path.addPath(cropPath, Offset.zero);
      canvas.drawPath(path, overlayPaint);
    }

    final linePaint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(cropPath, linePaint);

    final gridPaint = Paint()
      ..color = Colors.white.withAlpha(40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (var i = 1; i < 10; i++) {
      final t = i / 10;
      final top = Offset.lerp(corners![0], corners![3], t)!;
      final bottom = Offset.lerp(corners![1], corners![2], t)!;
      canvas.drawLine(top, bottom, gridPaint);

      final left = Offset.lerp(corners![0], corners![1], t)!;
      final right = Offset.lerp(corners![3], corners![2], t)!;
      canvas.drawLine(left, right, gridPaint);
    }
  }

  @override
  bool shouldRepaint(_CropOverlayPainter old) =>
      old.corners != corners || old.fullOverlay != fullOverlay;
}

class _MagnifierPainter extends CustomPainter {
  final ui.Image image;
  final double focalX;
  final double focalY;
  final double zoom;
  final double imgW;
  final double imgH;

  _MagnifierPainter({
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
  bool shouldRepaint(_MagnifierPainter old) =>
      old.focalX != focalX || old.focalY != focalY || old.zoom != zoom;
}
