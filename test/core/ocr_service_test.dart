import 'package:docscanner/core/ocr_service.dart';
import 'package:docscanner/domain/entities/ocr_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTextRecognizer extends Mock implements TextRecognizerInterface {}

void main() {
  late MockTextRecognizer mockRecognizer;
  late OcrService service;

  setUp(() {
    mockRecognizer = MockTextRecognizer();
    service = OcrService(recognizer: mockRecognizer);
  });

  group('OcrService', () {
    test('recognizeImage delegates to recognizer and returns result', () async {
      final expected = OcrResult(
        text: 'Hello World',
        blocks: [OcrBlock(text: 'Hello', confidence: 0.95)],
      );
      when(() => mockRecognizer.recognizeImage('path/to/image'))
          .thenAnswer((_) async => expected);

      final result = await service.recognizeImage('path/to/image');

      expect(result.text, 'Hello World');
      expect(result.blocks.length, 1);
      expect(result.blocks.first.text, 'Hello');
    });

    test('dispose calls recognizer.close', () {
      when(() => mockRecognizer.close()).thenReturn(null);

      service.dispose();

      verify(() => mockRecognizer.close()).called(1);
    });

    test('recognizeImage throws when recognizer fails', () async {
      when(() => mockRecognizer.recognizeImage(any()))
          .thenThrow(Exception('OCR failed'));

      expect(
        () => service.recognizeImage('path/to/image'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
