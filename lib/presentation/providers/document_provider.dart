import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local_datasource.dart';
import '../../data/repositories/document_repository_impl.dart';
import '../../data/services/file_service.dart';
import '../../domain/entities/scanned_document.dart';
import '../../domain/repositories/document_repository.dart';
import '../../domain/usecases/add_pages_to_document.dart';
import '../../domain/usecases/delete_document.dart';
import '../../domain/usecases/export_to_pdf.dart';
import '../../domain/usecases/get_all_documents.dart';
import '../../domain/usecases/rename_document.dart';
import '../../domain/usecases/scan_document.dart';

final _repositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepositoryImpl(LocalDataSource());
});

final _fileServiceProvider = Provider<FileService>((ref) {
  return FileService();
});

final _scanDocumentProvider = Provider<ScanDocument>((ref) {
  return ScanDocument(ref.watch(_repositoryProvider));
});

final _getAllDocumentsProvider = Provider<GetAllDocuments>((ref) {
  return GetAllDocuments(ref.watch(_repositoryProvider));
});

final _deleteDocumentProvider = Provider<DeleteDocument>((ref) {
  return DeleteDocument(ref.watch(_repositoryProvider));
});

final _renameDocumentProvider = Provider<RenameDocument>((ref) {
  return RenameDocument(ref.watch(_repositoryProvider));
});

final _exportToPdfProvider = Provider<ExportToPdf>((ref) {
  return ExportToPdf(ref.watch(_repositoryProvider));
});

final _addPagesToDocumentProvider = Provider<AddPagesToDocument>((ref) {
  return AddPagesToDocument(ref.watch(_repositoryProvider));
});

final documentListProvider =
    AsyncNotifierProvider<DocumentListNotifier, List<ScannedDocument>>(
  DocumentListNotifier.new,
);

class DocumentListNotifier extends AsyncNotifier<List<ScannedDocument>> {
  @override
  Future<List<ScannedDocument>> build() async {
    final getAll = ref.watch(_getAllDocumentsProvider);
    return getAll();
  }

  Future<void> scanFromBytes(Uint8List bytes) async {
    state = const AsyncLoading();
    try {
      final fileService = ref.read(_fileServiceProvider);
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final filePath = await fileService.savePageImage(id, bytes);
      final thumbPath = await fileService.saveThumbnail(id, bytes);
      final pdfPath = await fileService.generatePdf(id, [filePath]);
      await fileService.saveToGallery(filePath);

      final scan = ref.read(_scanDocumentProvider);
      await scan(
        id: id,
        filePath: filePath,
        thumbnailPath: thumbPath,
        pdfPath: pdfPath,
      );

      state = AsyncData(await ref.read(_getAllDocumentsProvider).call());
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> addPageToDocument(String documentId, Uint8List bytes) async {
    try {
      final fileService = ref.read(_fileServiceProvider);
      final path = await fileService.savePageImageWithSuffix(documentId, bytes);
      await fileService.saveToGallery(path);

      final addPages = ref.read(_addPagesToDocumentProvider);
      final updated = await addPages(documentId, [path]);

      final pdfPath = await fileService.generatePdf(documentId, updated.pages);
      await ref.read(_repositoryProvider).updatePdfPath(documentId, pdfPath);

      ref.invalidateSelf();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> delete(String id) async {
    try {
      final delete = ref.watch(_deleteDocumentProvider);
      await delete(id);
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> rename(String id, String newName) async {
    try {
      final rename = ref.watch(_renameDocumentProvider);
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
      final repo = ref.watch(_repositoryProvider);
      await repo.save(document);
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<File> exportToPdf() async {
    final docs = state.valueOrNull ?? [];
    if (docs.isEmpty) throw Exception('No documents to export');
    final export = ref.watch(_exportToPdfProvider);
    final allPagePaths = await export(docs);
    final fileService = ref.read(_fileServiceProvider);
    final path = await fileService.exportPdf(allPagePaths);
    return File(path);
  }
}
