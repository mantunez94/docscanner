import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ocr_service.dart';
import '../../domain/entities/ocr_result.dart';

final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  ref.onDispose(() => service.dispose());
  return service;
});

final ocrProvider = AsyncNotifierProvider<OcrNotifier, OcrResult?>(OcrNotifier.new);

class OcrNotifier extends AsyncNotifier<OcrResult?> {
  @override
  Future<OcrResult?> build() async => null;

  Future<void> recognizeImage(String imagePath) async {
    state = const AsyncLoading();
    try {
      final service = ref.read(ocrServiceProvider);
      final result = await service.recognizeImage(imagePath);
      state = AsyncData(result);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
