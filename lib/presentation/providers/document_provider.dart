import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<void> scanFromBytes(Uint8List bytes) async {
    try {
      final fileService = ref.read(fileServiceProvider);
      final pdfService = ref.read(pdfServiceProvider);
      final galleryService = ref.read(galleryServiceProvider);
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      final scan = ref.read(scanDocumentProvider);
      final filePath = await fileService.savePageImage(id, bytes);
      final thumbPath = await fileService.saveThumbnail(id, bytes);
      try {
        await scan(
          id: id,
          filePath: filePath,
          thumbnailPath: thumbPath,
          pdfPath: '',
        );
      } catch (_) {
        await _cleanupFiles([filePath, thumbPath]);
        rethrow;
      }

      final pdfPath = await pdfService.generatePdf(id, [filePath]);
      try {
        await ref.read(repositoryProvider).updatePdfPath(id, pdfPath);
      } catch (_) {
        await _cleanupFiles([pdfPath]);
        rethrow;
      }

      try {
        await galleryService.saveToGallery(filePath);
      } catch (e) {
        debugPrint('Gallery save failed: $e');
      }

      state = AsyncData(await ref.read(getAllDocumentsProvider).call());
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> _cleanupFiles(List<String> paths) async {
    for (final p in paths) {
      try {
        await File(p).delete();
      } catch (e) {
        debugPrint('Failed to cleanup file $p: $e');
      }
    }
  }

  Future<void> addPageToDocument(String documentId, Uint8List bytes) async {
    try {
      final fileService = ref.read(fileServiceProvider);
      final pdfService = ref.read(pdfServiceProvider);
      final galleryService = ref.read(galleryServiceProvider);
      final path = await fileService.savePageImageWithSuffix(documentId, bytes);

      final addPages = ref.read(addPagesToDocumentProvider);
      List<String> updatedPages;
      try {
        final updated = await addPages(documentId, [path]);
        updatedPages = updated.pages;
      } catch (_) {
        await _cleanupFiles([path]);
        rethrow;
      }

      final pdfPath = await pdfService.generatePdf(documentId, updatedPages);
      try {
        await ref.read(repositoryProvider).updatePdfPath(documentId, pdfPath);
      } catch (_) {
        await _cleanupFiles([pdfPath]);
        rethrow;
      }

      try {
        await galleryService.saveToGallery(path);
      } catch (e) {
        debugPrint('Gallery save failed: $e');
      }
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> delete(String id) async {
    try {
      final delete = ref.watch(deleteDocumentProvider);
      await delete(id);
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> removePage(String id, String pagePath) async {
    try {
      final removePage = ref.read(removePageFromDocumentProvider);
      final updated = await removePage(id, pagePath);
      final pdfService = ref.read(pdfServiceProvider);
      final pdfPath = await pdfService.generatePdf(id, updated.pages);
      await ref.read(repositoryProvider).updatePdfPath(id, pdfPath);
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> reorderPages(String id, List<String> reorderedPages) async {
    try {
      final repo = ref.read(repositoryProvider);
      await repo.reorderPages(id, reorderedPages);
      final pdfService = ref.read(pdfServiceProvider);
      final pdfPath = await pdfService.generatePdf(id, reorderedPages);
      await repo.updatePdfPath(id, pdfPath);
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> rename(String id, String newName) async {
    try {
      final rename = ref.watch(renameDocumentProvider);
      await rename(id, newName);
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
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

  Future<void> restore(ScannedDocument document) async {
    try {
      final repo = ref.watch(repositoryProvider);
      await repo.save(document);
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<File> exportToPdf() async {
    final docs = state.valueOrNull ?? [];
    if (docs.isEmpty) throw Exception('No documents to export');
    final export = ref.watch(exportToPdfProvider);
    final allPagePaths = await export(docs);
    final pdfService = ref.read(pdfServiceProvider);
    final path = await pdfService.exportPdf(allPagePaths);
    return File(path);
  }
}
