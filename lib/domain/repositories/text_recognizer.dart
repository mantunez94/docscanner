import '../entities/ocr_result.dart';

abstract class OcrTextRecognizer {
  Future<OcrResult> recognizeImage(String imagePath);
  void close();
}
