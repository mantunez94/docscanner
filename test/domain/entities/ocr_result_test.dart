import 'package:docscanner/domain/entities/ocr_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OcrResult', () {
    test('holds extracted text', () {
      const result = OcrResult(text: 'sample text');
      expect(result.text, 'sample text');
    });

    test('defaults to empty blocks list', () {
      const result = OcrResult(text: '');
      expect(result.blocks, isEmpty);
    });

    test('holds blocks with text and confidence', () {
      const result = OcrResult(
        text: 'Hello World',
        blocks: [
          OcrBlock(text: 'Hello', confidence: 0.95),
          OcrBlock(text: 'World', confidence: 0.87),
        ],
      );
      expect(result.blocks.length, 2);
      expect(result.blocks[0].text, 'Hello');
      expect(result.blocks[0].confidence, 0.95);
      expect(result.blocks[1].text, 'World');
      expect(result.blocks[1].confidence, 0.87);
    });
  });

  group('OcrBlock', () {
    test('holds text and confidence', () {
      const block = OcrBlock(text: 'test', confidence: 0.9);
      expect(block.text, 'test');
      expect(block.confidence, 0.9);
    });
  });
}
