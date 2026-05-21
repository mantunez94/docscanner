import 'dart:io';
import 'package:docscanner/domain/entities/scanned_document.dart';
import 'package:docscanner/domain/usecases/export_to_pdf.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExportToPdf', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('pdf_test_');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return tempDir.path;
          }
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
      tempDir.deleteSync(recursive: true);
    });

    test('creates a PDF file for documents with pages', () async {
      final imagePath = '${tempDir.path}/test.jpg';
      final image = img.Image(width: 10, height: 10);
      await File(imagePath).writeAsBytes(img.encodeJpg(image));

      final docs = [
        ScannedDocument(
          id: '1',
          pages: [imagePath],
          thumbnailPath: imagePath,
          createdAt: DateTime(2026, 5, 21),
          name: 'Doc 1',
        ),
      ];

      final export = ExportToPdf();
      final file = await export(docs);

      expect(file.existsSync(), isTrue);
      expect(file.path.endsWith('.pdf'), isTrue);
      expect(file.lengthSync(), greaterThan(0));

      file.deleteSync();
    });

    test('creates PDF with multiple pages from single document', () async {
      final imagePath1 = '${tempDir.path}/page1.jpg';
      final imagePath2 = '${tempDir.path}/page2.jpg';
      final image = img.Image(width: 5, height: 5);
      await File(imagePath1).writeAsBytes(img.encodeJpg(image));
      await File(imagePath2).writeAsBytes(img.encodeJpg(image));

      final docs = [
        ScannedDocument(
          id: '1',
          pages: [imagePath1, imagePath2],
          thumbnailPath: imagePath1,
          createdAt: DateTime(2026, 5, 21),
          name: 'Multi',
        ),
      ];

      final export = ExportToPdf();
      final file = await export(docs);

      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(0));

      file.deleteSync();
    });
  });
}
