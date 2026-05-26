import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/di/providers.dart';
import '../../domain/entities/scanned_document.dart';
import 'document_provider.dart';

class DocumentAdmin {
  DocumentAdmin(this._ref);
  final Ref _ref;

  Future<void> delete(String id) async {
    try {
      final delete = _ref.watch(deleteDocumentProvider);
      await delete(id);
      _ref.invalidate(documentListProvider);
    } catch (e) {
      _ref.read(documentListProvider.notifier).setError(e, StackTrace.current);
    }
  }

  Future<void> restore(ScannedDocument document) async {
    try {
      final repo = _ref.watch(repositoryProvider);
      await repo.save(document);
      _ref.invalidate(documentListProvider);
    } catch (e) {
      _ref.read(documentListProvider.notifier).setError(e, StackTrace.current);
    }
  }

  Future<void> rename(String id, String newName) async {
    try {
      final rename = _ref.watch(renameDocumentProvider);
      await rename(id, newName);
      _ref.invalidate(documentListProvider);
    } catch (e) {
      _ref.read(documentListProvider.notifier).setError(e, StackTrace.current);
    }
  }
}

final documentAdminProvider = Provider<DocumentAdmin>((ref) => DocumentAdmin(ref));
