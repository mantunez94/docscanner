import 'dart:io';
import 'dart:typed_data';
import '../../core/logger.dart';
import '../../domain/entities/scanned_document.dart';
import '../../domain/repositories/document_repository.dart';
import '../../domain/repositories/file_storage.dart';
import '../../domain/repositories/gallery_saver.dart';
import '../../domain/repositories/pdf_generator.dart';

class DocumentScanService {
  final FileStorage fileStorage;
  final PdfGenerator pdfGenerator;
  final GallerySaver gallerySaver;
  final DocumentRepository repository;

  DocumentScanService({
    required this.fileStorage,
    required this.pdfGenerator,
    required this.gallerySaver,
    required this.repository,
  });

  Future<String> scanFromBytes(Uint8List bytes) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final filePath = await fileStorage.savePageImage(id, bytes);
    final thumbPath = await fileStorage.saveThumbnail(id, bytes);

    try {
      await repository.save(ScannedDocument(
        id: id,
        pages: [filePath],
        thumbnailPath: thumbPath,
        createdAt: DateTime.now(),
        pdfPath: '',
      ));
    } catch (_) {
      await _cleanupFiles([filePath, thumbPath]);
      rethrow;
    }

    final pdfPath = await pdfGenerator.generatePdf(id, [filePath]);
    try {
      await repository.updatePdfPath(id, pdfPath);
    } catch (_) {
      await _cleanupFiles([pdfPath]);
      rethrow;
    }

    try {
      await gallerySaver.saveToGallery(filePath);
    } catch (e) {
      appLogger.e('Gallery save failed: $e');
    }

    return id;
  }

  Future<String> scanFromMultipleBytes(List<Uint8List> bytesList, {String? name}) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final paths = <String>[];
    for (var i = 0; i < bytesList.length; i++) {
      paths.add(await fileStorage.savePageImage('${id}_$i', bytesList[i]));
    }
    final thumbPath = await fileStorage.saveThumbnail(id, bytesList.first);

    final document = ScannedDocument(
      id: id,
      pages: [paths.first],
      thumbnailPath: thumbPath,
      createdAt: DateTime.now(),
      pdfPath: '',
      name: name,
    );

    try {
      await repository.save(document);
    } catch (_) {
      await _cleanupFiles(paths + [thumbPath]);
      rethrow;
    }

    if (paths.length > 1) {
      await repository.addPages(id, paths.sublist(1));
    }

    final pdfPath = await pdfGenerator.generatePdf(id, paths);
    try {
      await repository.updatePdfPath(id, pdfPath);
    } catch (_) {
      await _cleanupFiles([pdfPath]);
      rethrow;
    }

    for (final path in paths) {
      try {
        await gallerySaver.saveToGallery(path);
      } catch (e) {
        appLogger.e('Gallery save failed: $e');
      }
    }

    return id;
  }

  Future<void> addMultiplePagesToDocument(String documentId, List<Uint8List> bytesList) async {
    final paths = <String>[];
    for (final bytes in bytesList) {
      paths.add(await fileStorage.savePageImageWithSuffix(documentId, bytes));
    }

    List<String> updatedPages;
    try {
      final updated = await repository.addPages(documentId, paths);
      updatedPages = updated.pages;
    } catch (_) {
      await _cleanupFiles(paths);
      rethrow;
    }

    final pdfPath = await pdfGenerator.generatePdf(documentId, updatedPages);
    try {
      await repository.updatePdfPath(documentId, pdfPath);
    } catch (_) {
      await _cleanupFiles([pdfPath]);
      rethrow;
    }

    for (final path in paths) {
      try {
        await gallerySaver.saveToGallery(path);
      } catch (e) {
        appLogger.e('Gallery save failed: $e');
      }
    }
  }

  Future<void> addPageToDocument(String documentId, Uint8List bytes) async {
    final path = await fileStorage.savePageImageWithSuffix(documentId, bytes);

    List<String> updatedPages;
    try {
      final updated = await repository.addPages(documentId, [path]);
      updatedPages = updated.pages;
    } catch (_) {
      await _cleanupFiles([path]);
      rethrow;
    }

    final pdfPath = await pdfGenerator.generatePdf(documentId, updatedPages);
    try {
      await repository.updatePdfPath(documentId, pdfPath);
    } catch (_) {
      await _cleanupFiles([pdfPath]);
      rethrow;
    }

    try {
      await gallerySaver.saveToGallery(path);
    } catch (e) {
      appLogger.e('Gallery save failed: $e');
    }
  }

  Future<void> removePage(String id, String pagePath) async {
    final updated = await repository.removePage(id, pagePath);
    final pdfPath = await pdfGenerator.generatePdf(id, updated.pages);
    await repository.updatePdfPath(id, pdfPath);
  }

  Future<void> reorderPages(String id, List<String> reorderedPages) async {
    await repository.reorderPages(id, reorderedPages);
    final pdfPath = await pdfGenerator.generatePdf(id, reorderedPages);
    await repository.updatePdfPath(id, pdfPath);
  }

  Future<void> _cleanupFiles(List<String> paths) async {
    for (final p in paths) {
      try {
        await File(p).delete();
      } catch (e) {
        appLogger.e('Failed to cleanup file $p: $e');
      }
    }
  }
}
