import 'dart:io';
import 'dart:math' as math;
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

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    if (!mounted) return;
    _corners = _detectDocument(bytes);
    setState(() => _displayBytes = bytes);
  }

  List<cv.Point>? _detectDocument(Uint8List imageBytes) {
    try {
      final src = cv.imdecode(imageBytes, cv.IMREAD_COLOR);
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
        SnackBar(content: Text('OCR failed: $e')),
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

  @override
  Widget build(BuildContext context) {
    if (_displayBytes == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Preview')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Adjust & Confirm')),
      body: ClipRect(
        child: Stack(
          children: [
            Center(
              child: Image.memory(_displayBytes!, fit: BoxFit.contain),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black87,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _ocrLoading ? null : _runOcr,
                icon: _ocrLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.text_snippet, size: 18),
                label: Text(
                  _ocrLoading ? 'OCR...' : 'OCR',
                  style: const TextStyle(fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, 'retake'),
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Retake', style: TextStyle(fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: _saving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check, color: Colors.white, size: 28),
                onPressed: _saving ? null : _onConfirm,
              ),
            ],
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

          final (success, encoded) = cv.imencode(
            '.jpg',
            warped,
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
      if (!mounted) return;
      final bytes = _displayBytes;
      if (bytes != null) Navigator.pop(context, bytes);
    }
  }
}
