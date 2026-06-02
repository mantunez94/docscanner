import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:docscanner/l10n/app_localizations.dart';
import '../../core/document_boundary_detector.dart';
import '../../core/image_processing_service.dart';
import '../../core/logger.dart';
import '../widgets/boundary_overlay_painter.dart';
import '../widgets/captured_page_strip.dart';
import 'multi_page_review_screen.dart';
import 'preview_screen.dart';

class ScannerScreen extends StatefulWidget {
  final Future<void> Function(List<Uint8List> pages, String name)? onPagesSaved;
  final Set<String> existingNames;

  const ScannerScreen({
    super.key,
    this.onPagesSaved,
    this.existingNames = const {},
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
          _error = AppLocalizations.of(context)!.cameraPermissionDenied;
          _permissionDenied = true;
        });
      }
      return;
    }

    if (mounted) {
      final rationale = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(ctx)!.cameraPermissionNeeded),
          content: Text(
            AppLocalizations.of(ctx)!.cameraPermissionRationale,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.of(ctx)!.deny),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppLocalizations.of(ctx)!.allow),
            ),
          ],
        ),
      );

      if (rationale != true || !mounted) {
        setState(() => _error = AppLocalizations.of(context)!.cameraPermissionRequired);
        return;
      }
    }

    final result = await Permission.camera.request();
    if (!context.mounted) return;

    if (result.isGranted) {
      await _initCamera();
    } else if (result.isPermanentlyDenied) {
      setState(() {
        _error = AppLocalizations.of(context)!.cameraPermissionDenied;
        _permissionDenied = true;
      });
    } else {
      setState(() => _error = AppLocalizations.of(context)!.cameraPermissionRequired);
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _error = AppLocalizations.of(context)!.noCameraFound);
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
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.failedOpenCamera);
    }
  }

  void _startImageStream() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    _frameCount = 0;
    _streamActive = true;
    _controller!.startImageStream(_onImage);
  }

  void _stopImageStream() {
    if (!_streamActive) return;
    _streamActive = false;
    try {
      _controller?.stopImageStream();
    } catch (e) {
      appLogger.e('Failed to stop image stream: $e');
    }
  }

  void _onImage(CameraImage image) {
    if (!_streamActive) return;
    _imageWidth = image.width;
    _imageHeight = image.height;
    _frameCount++;
    const warmupFrames = 30;
    if (_frameCount <= warmupFrames) return;
    final cycleFrame = _frameCount - warmupFrames;
    if (cycleFrame % 10 != 0) return;

    try {

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
      appLogger.e('Error processing frame: $e');
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
          SnackBar(content: Text(AppLocalizations.of(context)!.torchNotAvailable)),
        );
      }
    }
  }

  @override
  void dispose() {
    _stopImageStream();
    try {
      _controller?.setFlashMode(FlashMode.off);
    } catch (e) {
      appLogger.e('setFlashMode failed on dispose: $e');
    }
    _controller?.dispose();
    _cleanupTempFiles();
    _pageScrollController.dispose();
    super.dispose();
  }

  void _cleanupTempFiles() {
    for (final path in _capturedPages) {
      try {
        File(path).deleteSync();
      } catch (e) {
        appLogger.e('Failed to delete temp file $path: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.scanDocument)),
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
                    label: Text(AppLocalizations.of(context)!.openSettings),
                  ),
                if (_permissionDenied) const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppLocalizations.of(context)!.goBack),
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
                        child: Text(AppLocalizations.of(context)!.retry),
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
            title: Text(AppLocalizations.of(ctx)!.discardPages),
            content: Text(
              AppLocalizations.of(ctx)!.discardPagesBody(_capturedPages.length),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppLocalizations.of(ctx)!.stay),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(AppLocalizations.of(ctx)!.discard),
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
          title: Text(_capturedPages.isEmpty
              ? AppLocalizations.of(context)!.scanDocument
              : AppLocalizations.of(context)!.scanNPages(_capturedPages.length)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: AppLocalizations.of(context)!.back,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Semantics(
            label: _torchOn ? AppLocalizations.of(context)!.torchOn : AppLocalizations.of(context)!.torchOff,
            child: Tooltip(
              message: _torchOn ? AppLocalizations.of(context)!.torchOn : AppLocalizations.of(context)!.torchOff,
              child: IconButton(
                onPressed: _toggleTorch,
                icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
              ),
            ),
          ),
          Semantics(
            label: _colorMode ? AppLocalizations.of(context)!.bwMode : AppLocalizations.of(context)!.colorMode,
            child: Tooltip(
              message: _colorMode ? AppLocalizations.of(context)!.bwMode : AppLocalizations.of(context)!.colorMode,
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
                    tooltip: AppLocalizations.of(context)!.doneScanning,
                    child: const Icon(Icons.check),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.large(
                    heroTag: 'capture',
                    onPressed: _capture,
                    tooltip: AppLocalizations.of(context)!.capturePhoto,
                    child: const Icon(Icons.camera_alt),
                  ),
                ],
              )
            : FloatingActionButton.large(
                heroTag: 'capture',
                onPressed: _capture,
                tooltip: AppLocalizations.of(context)!.capturePhoto,
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

        final offsetX = 0.0;
        final offsetY = 0.0;

        return Semantics(
          label: 'Document boundary overlay',
          excludeSemantics: true,
          child: CustomPaint(
                      painter: BoundaryOverlayPainter(
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
    return CapturedPageStrip(
      capturedPages: _capturedPages,
      onEditPage: _editPage,
      scrollController: _pageScrollController,
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
          existingNames: widget.existingNames,
          onSave: (paths, name) async {
            final bytesList = <Uint8List>[];
            for (final path in paths) {
              bytesList.add(await File(path).readAsBytes());
            }
            if (widget.onPagesSaved != null) {
              await widget.onPagesSaved!(bytesList, name);
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
        appLogger.e('Processing failed: $e');
        if (context.mounted) {
          setState(() => _processing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.failedProcessPage)),
          );
        }
      }
    } catch (e) {
      appLogger.e('Capture failed: $e');
      if (mounted) setState(() => _processing = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedCapture)),
        );
      }
    }
  }
}


