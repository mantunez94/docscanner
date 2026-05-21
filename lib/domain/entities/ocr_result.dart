class OcrResult {
  final String text;
  final List<OcrBlock> blocks;

  const OcrResult({required this.text, this.blocks = const []});
}

class OcrBlock {
  final String text;
  final double confidence;

  const OcrBlock({required this.text, required this.confidence});
}
