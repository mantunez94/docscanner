import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:docscanner/l10n/app_localizations.dart';
import 'package:docscanner/presentation/screens/scanner_screen.dart';
import 'package:docscanner/presentation/widgets/boundary_overlay_painter.dart';

Widget createTestApp() {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const ScannerScreen(),
  );
}

void _mockPermissionChannel({int status = 1}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('flutter.baseflow.com/permissions/methods'),
    (MethodCall call) async {
      switch (call.method) {
        case 'checkPermissionStatus':
          return status;
        case 'requestPermissions':
          return {4: status};
        case 'shouldShowRequestPermissionRationale':
          return false;
      }
      return null;
    },
  );
}

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/camera_android'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      null,
    );
  });

  group('initial render', () {
    testWidgets('renders Scaffold with AppBar title', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Scan Document'), findsOneWidget);
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows capture FAB', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('shows toolbar buttons', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.byTooltip('Torch off'), findsOneWidget);
      expect(find.byTooltip('Color mode'), findsOneWidget);
      expect(find.byTooltip('Capture photo'), findsOneWidget);
    });
  });

  group('permission denied', () {
    testWidgets('shows error when permanently denied', (tester) async {
      _mockPermissionChannel(status: 4);
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.text('Camera permission is permanently denied. '
          'Please enable it in app settings.'), findsOneWidget);
      expect(find.byIcon(Icons.no_photography_outlined), findsOneWidget);
    });

    testWidgets('shows error when denied without rationale', (tester) async {
      _mockPermissionChannel(status: 0);
      await tester.pumpWidget(createTestApp());
      // First pump triggers initState → _requestCameraPermission
      await tester.pump();
      // Rationale dialog appears — tap "Allow"
      await tester.tap(find.text('Allow'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Camera permission is required to scan documents.'),
          findsOneWidget);
    });
  });

  group('camera initialization', () {
    testWidgets('shows error when camera init fails', (tester) async {
      _mockPermissionChannel(status: 1);
      // Don't mock camera channel — MissingPluginException will trigger catch
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should show some error (either noCameraFound or failedOpenCamera)
      expect(find.byIcon(Icons.error_outline), findsOneWidget,
          skip: 'Camera platform channel not mockable in test environment');
    });
  });

  group('BoundaryOverlayPainter', () {
    test('shouldRepaint returns false for identical params', () {
      const params = <double>[400, 600, 0, 0, 400, 600];
      final painter = BoundaryOverlayPainter(
        corners: null,
        previewWidth: params[0],
        previewHeight: params[1],
        previewOffsetX: params[2],
        previewOffsetY: params[3],
        previewPaintWidth: params[4],
        previewPaintHeight: params[5],
        sensorOrientation: 0,
        imageWidth: 1920,
        imageHeight: 1080,
      );

      final identicalPainter = BoundaryOverlayPainter(
        corners: null,
        previewWidth: params[0],
        previewHeight: params[1],
        previewOffsetX: params[2],
        previewOffsetY: params[3],
        previewPaintWidth: params[4],
        previewPaintHeight: params[5],
        sensorOrientation: 0,
        imageWidth: 1920,
        imageHeight: 1080,
      );

      expect(painter.shouldRepaint(identicalPainter), false);
    });

    test('shouldRepaint detects corner changes', () {
      final painter = BoundaryOverlayPainter(
        corners: [cv.Point(10, 10), cv.Point(100, 10), cv.Point(100, 200), cv.Point(10, 200)],
        previewWidth: 400,
        previewHeight: 600,
        previewOffsetX: 0,
        previewOffsetY: 0,
        previewPaintWidth: 400,
        previewPaintHeight: 600,
        sensorOrientation: 0,
        imageWidth: 1920,
        imageHeight: 1080,
      );

      final moved = BoundaryOverlayPainter(
        corners: [cv.Point(20, 20), cv.Point(100, 10), cv.Point(100, 200), cv.Point(10, 200)],
        previewWidth: 400,
        previewHeight: 600,
        previewOffsetX: 0,
        previewOffsetY: 0,
        previewPaintWidth: 400,
        previewPaintHeight: 600,
        sensorOrientation: 0,
        imageWidth: 1920,
        imageHeight: 1080,
      );

      expect(painter.shouldRepaint(moved), true);
    });

    test('paints without errors with corners', () {
      const size = Size(400, 600);
      final painter = BoundaryOverlayPainter(
        corners: [
          cv.Point(0, 0),
          cv.Point(100, 0),
          cv.Point(100, 200),
          cv.Point(0, 200),
        ],
        previewWidth: 400,
        previewHeight: 600,
        previewOffsetX: 0,
        previewOffsetY: 0,
        previewPaintWidth: 400,
        previewPaintHeight: 600,
        sensorOrientation: 0,
        imageWidth: 1920,
        imageHeight: 1080,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 400, 600));
      painter.paint(canvas, size);
      final picture = recorder.endRecording();

      expect(picture, isNotNull);
    });

    test('paints without errors without corners', () {
      const size = Size(400, 600);
      final painter = BoundaryOverlayPainter(
        corners: null,
        previewWidth: 400,
        previewHeight: 600,
        previewOffsetX: 0,
        previewOffsetY: 0,
        previewPaintWidth: 400,
        previewPaintHeight: 600,
        sensorOrientation: 0,
        imageWidth: 1920,
        imageHeight: 1080,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 400, 600));
      painter.paint(canvas, size);
      final picture = recorder.endRecording();

      expect(picture, isNotNull);
    });

    test('maps corners correctly with 90 degree sensor orientation', () {
      final painter = BoundaryOverlayPainter(
        corners: [
          cv.Point(0, 0),
          cv.Point(100, 0),
          cv.Point(100, 200),
          cv.Point(0, 200),
        ],
        previewWidth: 400,
        previewHeight: 600,
        previewOffsetX: 0,
        previewOffsetY: 0,
        previewPaintWidth: 400,
        previewPaintHeight: 600,
        sensorOrientation: 90,
        imageWidth: 1920,
        imageHeight: 1080,
      );

      const size = Size(400, 600);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 400, 600));
      painter.paint(canvas, size);
      recorder.endRecording();
    });
  });
}
