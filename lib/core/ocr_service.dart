import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../domain/entities/ocr_result.dart' as domain;

abstract class TextRecognizerInterface {
  Future<domain.OcrResult> recognizeImage(String imagePath);
  void close();
}

class MlKitTextRecognizer implements TextRecognizerInterface {
  final TextRecognizer _inner;

  MlKitTextRecognizer() : _inner = TextRecognizer();

  @override
  Future<domain.OcrResult> recognizeImage(String imagePath) async {
    final inputImage = InputImage.fromFile(File(imagePath));
    final recognisedText = await _inner.processImage(inputImage);

    final blocks = recognisedText.blocks.map((b) {
      double total = 0;
      int count = 0;
      for (final line in b.lines) {
        for (final element in line.elements) {
          total += (element.confidence ?? 0.0);
          count++;
        }
      }
      final avgConfidence = count > 0 ? total / count : 0.0;
      return domain.OcrBlock(
        text: b.text,
        confidence: avgConfidence,
      );
    }).toList();

    return domain.OcrResult(
      text: recognisedText.text,
      blocks: blocks,
    );
  }

  @override
  void close() => _inner.close();
}

class OcrService {
  final TextRecognizerInterface _recognizer;

  OcrService({TextRecognizerInterface? recognizer})
      : _recognizer = recognizer ?? MlKitTextRecognizer();

  Future<domain.OcrResult> recognizeImage(String imagePath) =>
      _recognizer.recognizeImage(imagePath);

  void dispose() => _recognizer.close();
}
