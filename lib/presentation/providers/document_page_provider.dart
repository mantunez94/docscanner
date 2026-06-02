import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/di/providers.dart';
import 'document_provider.dart';

class DocumentPageManager {
  DocumentPageManager(this._ref);
  final Ref _ref;

  Future<void> addMultiplePagesToDocument(String documentId, List<Uint8List> bytesList) async {
    try {
      final service = _ref.read(documentScanServiceProvider);
      await service.addMultiplePagesToDocument(documentId, bytesList);
      _ref.invalidate(documentListProvider);
    } catch (e) {
      _ref.read(documentListProvider.notifier).setError(e, StackTrace.current);
    }
  }

  Future<void> addPageToDocument(String documentId, Uint8List bytes) async {
    try {
      final service = _ref.read(documentScanServiceProvider);
      await service.addPageToDocument(documentId, bytes);
      _ref.invalidate(documentListProvider);
    } catch (e) {
      _ref.read(documentListProvider.notifier).setError(e, StackTrace.current);
    }
  }

  Future<void> removePage(String id, String pagePath) async {
    try {
      final service = _ref.read(documentScanServiceProvider);
      await service.removePage(id, pagePath);
      _ref.invalidate(documentListProvider);
    } catch (e) {
      _ref.read(documentListProvider.notifier).setError(e, StackTrace.current);
    }
  }

  Future<void> reorderPages(String id, List<String> reorderedPages) async {
    try {
      final service = _ref.read(documentScanServiceProvider);
      await service.reorderPages(id, reorderedPages);
      _ref.invalidate(documentListProvider);
    } catch (e) {
      _ref.read(documentListProvider.notifier).setError(e, StackTrace.current);
    }
  }
}

final documentPageProvider = Provider<DocumentPageManager>((ref) => DocumentPageManager(ref));
