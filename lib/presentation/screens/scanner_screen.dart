import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/document_boundary_detector.dart';
import 'preview_screen.dart';

class ScannerScreen extends StatefulWidget {
  final bool autoCapture;
  final bool batchMode;
  final Future<void> Function(Uint8List bytes)? onPageScanned;

  const ScannerScreen({
    super.key,
    this.autoCapture = true,
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
  bool _autoCapturing = false;
  int _imageWidth = 0;
  int _imageHeight = 0;

  int _detectedCount = 0;
  DateTime? _autoCaptureCooldownUntil;

  bool get _isCoolingDown =>
      _autoCaptureCooldownUntil != null &&
      DateTime.now().isBefore(_autoCaptureCooldownUntil!);

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      _initCamera();
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
    if (!mounted) return;

    if (result.isGranted) {
      _initCamera();
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
      if (!mounted) return;
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
        if (_isCoolingDown) {
          _detectedCount = 0;
        } else {
          _autoCaptureCooldownUntil = null;
          _checkAutoCapture(corners);
        }
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
    HapticFeedback.mediumImpact();
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
        if (confirm == true && mounted) {
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
        actions: [
          if (_autoCapturing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_isCoolingDown)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Tooltip(
                message: 'Cooldown',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(100)),
                    const SizedBox(width: 4),
                    Text('wait',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(100))),
                  ],
                ),
              ),
            )
          else if (widget.autoCapture && _detectedCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final filled = i < _detectedCount;
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withAlpha(40),
                    ),
                  );
                }),
              ),
            ),
        ],
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
            isAutoCapturing: _autoCapturing,
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
      if (!mounted) return;

      final result = await Navigator.push<Object>(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewScreen(imagePath: copy.path),
        ),
      );

      if (!mounted) return;
      if (result is Uint8List) {
        if (widget.batchMode && widget.onPageScanned != null) {
          await widget.onPageScanned!(result);
          if (!mounted) return;
          _autoCapturing = false;
          _detectedCount = 0;
          _corners = null;

          _stopImageStream();
          await Future.delayed(const Duration(milliseconds: 350));

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

          if (!mounted) return;
          if (scanAnother == true) {
            setState(() {
              _autoCapturing = false;
              _detectedCount = 0;
              _corners = null;
            });
            _startImageStream();
            setState(() {
              _autoCaptureCooldownUntil = DateTime.now().add(const Duration(milliseconds: 1500));
            });
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
          _autoCapturing = false;
          _detectedCount = 0;
          _corners = null;
          _startImageStream();
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
  final bool isAutoCapturing;

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
    this.isAutoCapturing = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
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
        oldDelegate.isAutoCapturing != isAutoCapturing ||
        oldDelegate.previewOffsetX != previewOffsetX ||
        oldDelegate.previewOffsetY != previewOffsetY ||
        oldDelegate.previewPaintWidth != previewPaintWidth ||
        oldDelegate.previewPaintHeight != previewPaintHeight;
  }
}
