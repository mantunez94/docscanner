import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/di/providers.dart';
import '../../domain/entities/scanned_document.dart';
import 'document_provider.dart';

class DocumentScan {
  DocumentScan(this._ref);
  final Ref _ref;

  Future<void> scanFromBytes(Uint8List bytes) async {
    try {
      final fileService = _ref.read(fileServiceProvider);
      final pdfService = _ref.read(pdfServiceProvider);
      final galleryService = _ref.read(galleryServiceProvider);
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      final scan = _ref.read(scanDocumentProvider);
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
        await cleanupFiles([filePath, thumbPath]);
        rethrow;
      }

      final pdfPath = await pdfService.generatePdf(id, [filePath]);
      try {
        await _ref.read(repositoryProvider).updatePdfPath(id, pdfPath);
      } catch (_) {
        await cleanupFiles([pdfPath]);
        rethrow;
      }

      try {
        await galleryService.saveToGallery(filePath);
      } catch (e) {
        debugPrint('Gallery save failed: $e');
      }

      _ref.invalidate(documentListProvider);
    } catch (e) {
      _ref.read(documentListProvider.notifier).setError(e, StackTrace.current);
    }
  }

  Future<void> scanFromMultipleBytes(List<Uint8List> bytesList, [String? name]) async {
    try {
      final fileService = _ref.read(fileServiceProvider);
      final pdfService = _ref.read(pdfServiceProvider);
      final galleryService = _ref.read(galleryServiceProvider);
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      final paths = <String>[];
      for (var i = 0; i < bytesList.length; i++) {
        paths.add(await fileService.savePageImage('${id}_$i', bytesList[i]));
      }
      final thumbPath = await fileService.saveThumbnail(id, bytesList.first);
      final document = ScannedDocument(
        id: id,
        pages: [paths.first],
        thumbnailPath: thumbPath,
        createdAt: DateTime.now(),
        pdfPath: '',
        name: name,
      );
      try {
        await _ref.read(repositoryProvider).save(document);
      } catch (_) {
        await cleanupFiles(paths + [thumbPath]);
        rethrow;
      }

      if (paths.length > 1) {
        final addPages = _ref.read(addPagesToDocumentProvider);
        await addPages(id, paths.sublist(1));
      }

      final pdfPath = await pdfService.generatePdf(id, paths);
      try {
        await _ref.read(repositoryProvider).updatePdfPath(id, pdfPath);
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
}

final documentScanProvider = Provider<DocumentScan>((ref) => DocumentScan(ref));
