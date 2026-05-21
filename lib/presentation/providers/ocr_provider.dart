import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ocr_service.dart';
import '../../domain/entities/ocr_result.dart';

final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  ref.onDispose(() => service.dispose());
  return service;
});

final ocrResultProvider = StateProvider<OcrResult?>((ref) => null);

final ocrLoadingProvider = StateProvider<bool>((ref) => false);

final ocrTextProvider = Provider<String>((ref) {
  final result = ref.watch(ocrResultProvider);
  return result?.text ?? '';
});
