import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/di/providers.dart';
import 'document_provider.dart';

class DocumentPageManager {
  DocumentPageManager(this._ref);
  final Ref _ref;

  Future<void> addMultiplePagesToDocument(String documentId, List<Uint8List> bytesList) async {
    try {
      final fileService = _ref.read(fileServiceProvider);
      final pdfService = _ref.read(pdfServiceProvider);
      final galleryService = _ref.read(galleryServiceProvider);
      final paths = <String>[];
      for (final bytes in bytesList) {
        paths.add(await fileService.savePageImageWithSuffix(documentId, bytes));
      }

      final addPages = _ref.read(addPagesToDocumentProvider);
      List<String> updatedPages;
      try {
        final updated = await addPages(documentId, paths);
        updatedPages = updated.pages;
      } catch (_) {
        await cleanupFiles(paths);
        rethrow;
      }

      final pdfPath = await pdfService.generatePdf(documentId, updatedPages);
      try {
        await _ref.read(repositoryProvider).updatePdfPath(documentId, pdfPath);
      } catch (_) {
        await cleanupFiles([pdfPath]);
        rethrow;
      }

      try {
        for (final path in paths) {
          await galleryService.saveToGallery(path);
        }
      } catch (e) {
        debugPrint('Gallery save failed: $e');
      }
      _ref.invalidate(documentListProvider);
    } catch (e) {
      _ref.read(documentListProvider.notifier).setError(e, StackTrace.current);
    }
  }

  Future<void> addPageToDocument(String documentId, Uint8List bytes) async {
    try {
      final fileService = _ref.read(fileServiceProvider);
      final pdfService = _ref.read(pdfServiceProvider);
      final galleryService = _ref.read(galleryServiceProvider);
      final path = await fileService.savePageImageWithSuffix(documentId, bytes);

      final addPages = _ref.read(addPagesToDocumentProvider);
      List<String> updatedPages;
      try {
        final updated = await addPages(documentId, [path]);
        updatedPages = updated.pages;
      } catch (_) {
        await cleanupFiles([path]);
        rethrow;
      }

      final pdfPath = await pdfService.generatePdf(documentId, updatedPages);
      try {
        await _ref.read(repositoryProvider).updatePdfPath(documentId, pdfPath);
      } catch (_) {
        await cleanupFiles([pdfPath]);
        rethrow;
      }

      try {
        await galleryService.saveToGallery(path);
      } catch (e) {
        debugPrint('Gallery save failed: $e');
      }
      _ref.invalidate(documentListProvider);
    } catch (e) {
      _ref.read(documentListProvider.notifier).setError(e, StackTrace.current);
    }
  }

  Future<void> removePage(String id, String pagePath) async {
    try {
      final removePage = _ref.read(removePageFromDocumentProvider);
      final updated = await removePage(id, pagePath);
      final pdfService = _ref.read(pdfServiceProvider);
      final pdfPath = await pdfService.generatePdf(id, updated.pages);
      await _ref.read(repositoryProvider).updatePdfPath(id, pdfPath);
      _ref.invalidate(documentListProvider);
    } catch (e) {
      _ref.read(documentListProvider.notifier).setError(e, StackTrace.current);
    }
  }

  Future<void> reorderPages(String id, List<String> reorderedPages) async {
    try {
      final repo = _ref.read(repositoryProvider);
      await repo.reorderPages(id, reorderedPages);
      final pdfService = _ref.read(pdfServiceProvider);
      final pdfPath = await pdfService.generatePdf(id, reorderedPages);
      await repo.updatePdfPath(id, pdfPath);
      _ref.invalidate(documentListProvider);
    } catch (e) {
      _ref.read(documentListProvider.notifier).setError(e, StackTrace.current);
    }
  }
}

final documentPageProvider = Provider<DocumentPageManager>((ref) => DocumentPageManager(ref));
