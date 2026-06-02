import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/logger.dart';
import '../../data/di/providers.dart';
import '../../domain/entities/scanned_document.dart';

final documentListProvider =
    AsyncNotifierProvider<DocumentListNotifier, List<ScannedDocument>>(
  DocumentListNotifier.new,
);

class DocumentListNotifier extends AsyncNotifier<List<ScannedDocument>> {
  @override
  Future<List<ScannedDocument>> build() async {
    final getAll = ref.watch(getAllDocumentsProvider);
    return getAll();
  }


  ScannedDocument? getDocument(String id) {
    final docs = state.valueOrNull;
    if (docs == null) return null;
    try {
      return docs.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  void setError(Object e, StackTrace st) {
    state = AsyncError(e, st);
  }
}

Future<void> cleanupFiles(List<String> paths) async {
  for (final p in paths) {
    try {
      await File(p).delete();
    } catch (e) {
      appLogger.e('Failed to cleanup file $p: $e');
    }
  }
}
