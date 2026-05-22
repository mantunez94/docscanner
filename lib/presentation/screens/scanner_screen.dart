import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:path_provider/path_provider.dart';
import '../../core/document_boundary_detector.dart';
import 'preview_screen.dart';

class ScannerScreen extends StatefulWidget {
  final bool autoCapture;

  const ScannerScreen({super.key, this.autoCapture = true});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _controller;
  bool _initialized = false;
  String? _error;
  bool _streamActive = false;
  int _frameCount = 0;

  final _boundaryDetector = DocumentBoundaryDetector();
  List<cv.Point>? _corners;
  bool _autoCapturing = false;
  int _imageWidth = 0;
  int _imageHeight = 0;

  int _detectedCount = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _error = 'No camera found');
        return;
      }
      final controller = CameraController(
        cameras[0],
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _initialized = true;
      });
      _startImageStream();
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to initialize camera: $e');
    }
  }

  void _startImageStream() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    _streamActive = true;
    _controller!.startImageStream(_onImage);
  }

  void _stopImageStream() {
    _streamActive = false;
    try {
      _controller?.stopImageStream();
    } catch (_) {}
  }

  void _onImage(CameraImage image) {
    if (!_streamActive) return;
    _frameCount++;
    if (_frameCount % 10 != 0) return;

    try {
      _imageWidth = image.width;
      _imageHeight = image.height;

      final yPlane = image.planes[0];
      final corners = _boundaryDetector.detectBoundary(
        yPlane.bytes,
        image.width,
        image.height,
        stride: yPlane.bytesPerRow,
      );

      if (mounted) {
        setState(() => _corners = corners);
      }

      if (widget.autoCapture && !_autoCapturing) {
        _checkAutoCapture(corners);
      }
    } catch (e) {
      debugPrint('Error processing frame: $e');
    }
  }

  void _checkAutoCapture(List<cv.Point>? corners) {
    if (corners == null || corners.length < 4) {
      _detectedCount = 0;
      return;
    }

    final area = _boundaryDetector.computeAreaFraction(corners, _imageWidth, _imageHeight);
    if (area < 0.12) {
      _detectedCount = 0;
      return;
    }

    _detectedCount++;
    if (_detectedCount >= 5) {
      _triggerAutoCapture();
    }
  }

  void _triggerAutoCapture() {
    _autoCapturing = true;
    _capture();
  }

  @override
  void dispose() {
    _stopImageStream();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scan Document')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Document'),
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Home',
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_autoCapturing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: !_initialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CameraPreview(_controller!),
                _buildOverlay(),
              ],
            ),
    );
  }

  Widget _buildOverlay() {
    final preview = _controller?.value.previewSize;
    if (preview == null) return const SizedBox.shrink();

    return CustomPaint(
      size: Size.infinite,
      painter: _BoundaryOverlayPainter(
        corners: _corners,
        previewWidth: preview.width,
        previewHeight: preview.height,
        sensorOrientation: _controller!.value.description.sensorOrientation,
        imageWidth: _imageWidth,
        imageHeight: _imageHeight,
        isAutoCapturing: _autoCapturing,
      ),
    );
  }

  Future<void> _capture() async {
    try {
      final file = await _controller!.takePicture();
      final dir = await getTemporaryDirectory();
      final copy = await File(file.path).copy('${dir.path}/temp_scan.jpg');
      if (!mounted) return;

      final result = await Navigator.push<Object>(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewScreen(imagePath: copy.path),
        ),
      );

      if (!mounted) return;
      if (result is Uint8List) {
        Navigator.pop<Uint8List>(context, result);
      } else if (result == 'retake') {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Retake?'),
            content: const Text('The current page will be discarded.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Retake'),
              ),
            ],
          ),
        );
        if (!context.mounted) return;
        if (confirm == true) {
          _autoCapturing = false;
          _detectedCount = 0;
          _corners = null;
        } else {
          Navigator.pop(context);
        }
      } else {
        _autoCapturing = false;
      }
    } catch (e) {
      _autoCapturing = false;
      _startImageStream();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _BoundaryOverlayPainter extends CustomPainter {
  final List<cv.Point>? corners;
  final double previewWidth;
  final double previewHeight;
  final int sensorOrientation;
  final int imageWidth;
  final int imageHeight;
  final bool isAutoCapturing;

  _BoundaryOverlayPainter({
    this.corners,
    required this.previewWidth,
    required this.previewHeight,
    required this.sensorOrientation,
    required this.imageWidth,
    required this.imageHeight,
    this.isAutoCapturing = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / previewWidth;
    final scaleY = size.height / previewHeight;

    final paint = Paint()
      ..color = Colors.black.withAlpha(100)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = isAutoCapturing ? Colors.greenAccent : Colors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final cornerPaint = Paint()
      ..color = isAutoCapturing ? Colors.greenAccent : Colors.cyanAccent
      ..style = PaintingStyle.fill;

    if (corners != null && corners!.length >= 4) {
      final pts = _mapCorners(corners!, scaleX, scaleY);

      final docPath = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (var i = 1; i < pts.length; i++) {
        docPath.lineTo(pts[i].dx, pts[i].dy);
      }
      docPath.close();

      canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
          docPath,
        ),
        paint,
      );

      canvas.drawPath(docPath, borderPaint);

      for (final p in pts) {
        canvas.drawCircle(p, 6, cornerPaint);
        canvas.drawCircle(p, 6, Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
      }
    } else {
      final rect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.85,
        height: size.height * 0.55,
      );

      canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
          Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12))),
        ),
        paint,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(12)),
        borderPaint,
      );
    }
  }

  List<Offset> _mapCorners(List<cv.Point> corners, double scaleX, double scaleY) {
    return corners.map((p) {
      double x = p.x.toDouble();
      double y = p.y.toDouble();

      final w = imageWidth.toDouble();
      final h = imageHeight.toDouble();

      switch (sensorOrientation) {
        case 90:
          final tmp = x;
          x = h - y;
          y = tmp;
        case 180:
          x = w - x;
          y = h - y;
        case 270:
          final tmp = x;
          x = y;
          y = w - tmp;
      }

      final displayW = (sensorOrientation == 90 || sensorOrientation == 270) ? h : w;
      final displayH = (sensorOrientation == 90 || sensorOrientation == 270) ? w : h;

      return Offset(
        x * scaleX * previewWidth / displayW,
        y * scaleY * previewHeight / displayH,
      );
    }).toList();
  }

  @override
  bool shouldRepaint(covariant _BoundaryOverlayPainter oldDelegate) {
    return oldDelegate.corners != corners || oldDelegate.isAutoCapturing != isAutoCapturing;
  }
}
