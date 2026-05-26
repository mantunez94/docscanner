import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/document_boundary_detector.dart';
import '../../core/image_processing_service.dart';
import 'multi_page_review_screen.dart';
import 'preview_screen.dart';

class ScannerScreen extends StatefulWidget {
  final Future<void> Function(Uint8List bytes)? onPageScanned;

  const ScannerScreen({
    super.key,
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

  bool _colorMode = false;
  bool _torchOn = false;
  final _capturedPages = <String>[];
  bool _processing = false;
  final _pageScrollController = ScrollController();

  final _boundaryDetector = DocumentBoundaryDetector();
  final _imageProcessingService = ImageProcessingService();
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

  Future<void> _toggleTorch() async {
    try {
      final mode = _torchOn ? FlashMode.off : FlashMode.torch;
      await _controller?.setFlashMode(mode);
      if (mounted) setState(() => _torchOn = !_torchOn);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Torch not available on this device')),
        );
      }
    }
  }

  @override
  void dispose() {
    _stopImageStream();
    _controller?.setFlashMode(FlashMode.off);
    _controller?.dispose();
    _cleanupTempFiles();
    _pageScrollController.dispose();
    super.dispose();
  }

  void _cleanupTempFiles() {
    for (final path in _capturedPages) {
      try {
        File(path).deleteSync();
      } catch (_) {}
    }
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
      canPop: _capturedPages.isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ctx = context;
        final confirm = await showDialog<bool>(
          context: ctx,
          builder: (ctx) => AlertDialog(
            title: const Text('Discard pages?'),
            content: Text(
              'You have ${_capturedPages.length} page${_capturedPages.length == 1 ? '' : 's'} in progress. Discard them?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Stay'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_capturedPages.isEmpty ? 'Scan Document' : 'Scan (${_capturedPages.length} page${_capturedPages.length == 1 ? '' : 's'})'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Semantics(
            label: _torchOn ? 'Turn off torch' : 'Turn on torch',
            child: Tooltip(
              message: _torchOn ? 'Torch on' : 'Torch off',
              child: IconButton(
                onPressed: _toggleTorch,
                icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
              ),
            ),
          ),
          Semantics(
            label: _colorMode ? 'Switch to black and white' : 'Switch to color',
            child: Tooltip(
              message: _colorMode ? 'B&W mode' : 'Color mode',
              child: IconButton(
                onPressed: () => setState(() => _colorMode = !_colorMode),
                icon: Icon(_colorMode ? Icons.filter_b_and_w : Icons.color_lens),
              ),
            ),
          ),
        ],
        ),
        floatingActionButton: _capturedPages.isNotEmpty && !_processing
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'done',
                    onPressed: _reviewPages,
                    tooltip: 'Done scanning',
                    child: const Icon(Icons.check),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.large(
                    heroTag: 'capture',
                    onPressed: _capture,
                    tooltip: 'Capture photo',
                    child: const Icon(Icons.camera_alt),
                  ),
                ],
              )
            : FloatingActionButton.large(
                heroTag: 'capture',
                onPressed: _capture,
                tooltip: 'Capture photo',
                child: _processing
                    ? const SizedBox(
                        width: 28, height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.camera_alt),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

        body: !_initialized
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        CameraPreview(_controller!),
                        Positioned.fill(child: _buildOverlay()),
                      ],
                    ),
                  ),
                  if (_capturedPages.isNotEmpty)
                    _buildPageStrip(),
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

  Widget _buildPageStrip() {
    return Container(
      height: 80,
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Semantics(
            label: '${_capturedPages.length} pages captured',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              child: Text(
                '${_capturedPages.length}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ListView.separated(
              controller: _pageScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _capturedPages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                return Semantics(
                  label: 'Page ${index + 1} thumbnail',
                  child: GestureDetector(
                    onTap: () => _editPage(index),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        File(_capturedPages[index]),
                        width: 56,
                        height: 72,
                        fit: BoxFit.cover,
                        cacheWidth: 120,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editPage(int index) async {
    final result = await Navigator.push<Object>(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewScreen(
          imagePath: _capturedPages[index],
          initialColorMode: _colorMode,
        ),
      ),
    );
    if (!context.mounted) return;
    if (result is Uint8List) {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/multipage_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(path).writeAsBytes(result);
      setState(() => _capturedPages[index] = path);
    }
  }

  Future<void> _reviewPages() async {
    _stopImageStream();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MultiPageReviewScreen(
          pagePaths: List.from(_capturedPages),
          colorMode: _colorMode,
          onSave: (paths) async {
            for (final path in paths) {
              final bytes = await File(path).readAsBytes();
              if (widget.onPageScanned != null) {
                await widget.onPageScanned!(bytes);
              }
            }
          },
        ),
      ),
    );
    if (!context.mounted) return;
    if (result == true) {
      _capturedPages.clear();
      Navigator.pop<bool>(context, true);
    } else {
      _startImageStream();
    }
  }

  Future<void> _capture() async {
    if (_processing) return;
    try {
      final file = await _controller!.takePicture();
      final rawBytes = await file.readAsBytes();
      if (!context.mounted) return;

      setState(() => _processing = true);
      try {
        final src = cv.imdecode(rawBytes, cv.IMREAD_COLOR);
        final corners = src.rows > 0
            ? _imageProcessingService.detectDocumentFromMat(src)
            : null;
        final (processed, _) = _imageProcessingService.processScan(
          rawBytes, corners, _colorMode,
        );
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/page_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await File(path).writeAsBytes(processed);
        if (context.mounted) {
          setState(() {
            _capturedPages.add(path);
            _processing = false;
          });
          unawaited(
            _pageScrollController.animateTo(
              _pageScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            ),
          );
        }
      } catch (e) {
        debugPrint('Processing failed: $e');
        if (context.mounted) {
          setState(() => _processing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to process page. Please try again.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Capture failed: $e');
      if (mounted) setState(() => _processing = false);
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
