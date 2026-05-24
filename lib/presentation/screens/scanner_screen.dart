import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/document_boundary_detector.dart';
import 'preview_screen.dart';

class ScannerScreen extends StatefulWidget {
  final bool batchMode;
  final Future<void> Function(Uint8List bytes)? onPageScanned;

  const ScannerScreen({
    super.key,
    this.batchMode = false,
    this.onPageScanned,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _controller;
  bool _initialized = false;
  String? _error;
  bool _permissionDenied = false;
  bool _streamActive = false;
  int _frameCount = 0;

  final _boundaryDetector = DocumentBoundaryDetector();
  List<cv.Point>? _corners;
  int _imageWidth = 0;
  int _imageHeight = 0;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      await _initCamera();
      return;
    }

    if (status.isPermanentlyDenied) {
      if (mounted) {
        setState(() {
          _error = 'Camera permission is permanently denied. Please enable it in app settings.';
          _permissionDenied = true;
        });
      }
      return;
    }

    if (mounted) {
      final rationale = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Camera permission needed'),
          content: const Text(
            'DocScanner needs access to your camera to scan documents. '
            'No photos are taken without your action.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Deny'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Allow'),
            ),
          ],
        ),
      );

      if (rationale != true || !mounted) {
        setState(() => _error = 'Camera permission is required to scan documents.');
        return;
      }
    }

    final result = await Permission.camera.request();
    if (!context.mounted) return;

    if (result.isGranted) {
      await _initCamera();
    } else if (result.isPermanentlyDenied) {
      setState(() {
        _error = 'Camera permission is permanently denied. Please enable it in app settings.';
        _permissionDenied = true;
      });
    } else {
      setState(() => _error = 'Camera permission is required to scan documents.');
    }
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
      if (!context.mounted) return;
      setState(() {
        _controller = controller;
        _initialized = true;
      });
      _startImageStream();
    } catch (_) {
      if (mounted) setState(() => _error = 'Failed to open camera. Please try again.');
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
    } catch (e) {
      debugPrint('Failed to stop image stream: $e');
    }
  }

  void _onImage(CameraImage image) {
    if (!_streamActive) return;
    _frameCount++;
    if (_frameCount % 10 != 0) return;

    try {
      _imageWidth = image.width;
      _imageHeight = image.height;

      final yPlane = image.planes[0];
      final newCorners = _boundaryDetector.detectBoundary(
        yPlane.bytes,
        image.width,
        image.height,
        stride: yPlane.bytesPerRow,
      );

      final cornersChanged = !_cornersEqual(_corners, newCorners);
      if (cornersChanged) {
        _corners = newCorners;
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Error processing frame: $e');
    }
  }

  bool _cornersEqual(List<cv.Point>? a, List<cv.Point>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].x != b[i].x || a[i].y != b[i].y) return false;
    }
    return true;
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
                Icon(
                  _permissionDenied ? Icons.no_photography_outlined : Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                if (_permissionDenied)
                  FilledButton.icon(
                    onPressed: () async {
                      await openAppSettings();
                    },
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text('Open Settings'),
                  ),
                if (_permissionDenied) const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go back'),
                    ),
                    if (!_permissionDenied) ...[
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _error = null;
                            _permissionDenied = false;
                          });
                          _requestCameraPermission();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: !widget.batchMode,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !widget.batchMode) return;
        final ctx = context;
        final confirm = await showDialog<bool>(
          context: ctx,
          builder: (ctx) => AlertDialog(
            title: const Text('Discard batch?'),
            content: const Text(
              'You have pages in the current batch. Do you want to discard them and go back?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Stay'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          Navigator.pop(context, true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.batchMode ? 'Batch Scan' : 'Scan Document'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        ),
        floatingActionButton: FloatingActionButton.large(
          onPressed: _capture,
          tooltip: 'Capture photo',
          child: const Icon(Icons.camera_alt),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

        body: !_initialized
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  CameraPreview(_controller!),
                  Positioned.fill(child: _buildOverlay()),
                ],
              ),
        ),
      );
  }

  Widget _buildOverlay() {
    final preview = _controller?.value.previewSize;
    if (preview == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final bodyW = constraints.maxWidth;
        final bodyH = constraints.maxHeight;

        final orientation = _controller!.value.deviceOrientation;
        final isLandscape = orientation == DeviceOrientation.landscapeLeft ||
            orientation == DeviceOrientation.landscapeRight;
        final camAspect = isLandscape
            ? preview.width / preview.height
            : preview.height / preview.width;

        double paintW = bodyW;
        double paintH = paintW / camAspect;
        if (paintH > bodyH) {
          paintH = bodyH;
          paintW = paintH * camAspect;
        }

        final offsetX = (bodyW - paintW) / 2;
        final offsetY = (bodyH - paintH) / 2;

        return Semantics(
          label: 'Document boundary overlay',
          excludeSemantics: true,
          child: CustomPaint(
            painter: _BoundaryOverlayPainter(
            corners: _corners,
            previewWidth: preview.width,
            previewHeight: preview.height,
            previewOffsetX: offsetX,
            previewOffsetY: offsetY,
            previewPaintWidth: paintW,
            previewPaintHeight: paintH,
            sensorOrientation: _controller!.value.description.sensorOrientation,
            imageWidth: _imageWidth,
            imageHeight: _imageHeight,
          ),
          ),
        );
      },
    );
  }

  Future<void> _capture() async {
    try {
      final file = await _controller!.takePicture();
      final dir = await getTemporaryDirectory();
      final copy = await File(file.path).copy('${dir.path}/temp_scan.jpg');
      if (!context.mounted) return;

      final result = await Navigator.push<Object>(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewScreen(imagePath: copy.path),
        ),
      );

      if (!context.mounted) return;
      if (result is Uint8List) {
        if (widget.batchMode && widget.onPageScanned != null) {
          await widget.onPageScanned!(result);
          if (!context.mounted) return;
          _corners = null;

          _stopImageStream();
          await Future.delayed(const Duration(milliseconds: 350));
          if (!context.mounted) return;

          final scanAnother = await showDialog<bool>(
            context: context,
            barrierDismissible: true,
            builder: (ctx) => PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) Navigator.pop(ctx, false);
              },
              child: AlertDialog(
                title: const Text('Page saved'),
                content: const Text('Scan another page?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Done'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Scan another'),
                  ),
                ],
              ),
            ),
          );

          if (!context.mounted) return;
          if (scanAnother == true) {
            setState(() {
              _corners = null;
            });
            _startImageStream();
          } else {
            Navigator.pop(context, true);
          }
        } else {
          Navigator.pop<Uint8List>(context, result);
        }
      } else if (result == 'retake') {
        _stopImageStream();
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
          _corners = null;
          _startImageStream();
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      _startImageStream();
      if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong while capturing. Please try again.')),
      );
      }
    }
  }
}

class _BoundaryOverlayPainter extends CustomPainter {
  final List<cv.Point>? corners;
  final double previewWidth;
  final double previewHeight;
  final double previewOffsetX;
  final double previewOffsetY;
  final double previewPaintWidth;
  final double previewPaintHeight;
  final int sensorOrientation;
  final int imageWidth;
  final int imageHeight;

  _BoundaryOverlayPainter({
    this.corners,
    required this.previewWidth,
    required this.previewHeight,
    required this.previewOffsetX,
    required this.previewOffsetY,
    required this.previewPaintWidth,
    required this.previewPaintHeight,
    required this.sensorOrientation,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withAlpha(100)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final cornerPaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.fill;

    if (corners != null && corners!.length >= 4) {
      final pts = _mapCorners(corners!);

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
      final centerX = previewOffsetX + previewPaintWidth / 2;
      final centerY = previewOffsetY + previewPaintHeight / 2;

      final rect = Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: previewPaintWidth * 0.85,
        height: previewPaintHeight * 0.55,
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

  List<Offset> _mapCorners(List<cv.Point> corners) {
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
        previewOffsetX + x * previewPaintWidth / displayW,
        previewOffsetY + y * previewPaintHeight / displayH,
      );
    }).toList();
  }

  @override
  bool shouldRepaint(covariant _BoundaryOverlayPainter oldDelegate) {
    return oldDelegate.corners != corners ||
        oldDelegate.previewOffsetX != previewOffsetX ||
        oldDelegate.previewOffsetY != previewOffsetY ||
        oldDelegate.previewPaintWidth != previewPaintWidth ||
        oldDelegate.previewPaintHeight != previewPaintHeight;
  }
}
