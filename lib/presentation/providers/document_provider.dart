import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local_datasource.dart';
import '../../data/repositories/document_repository_impl.dart';
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
  return ExportToPdf();
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
    final scan = ref.watch(_scanDocumentProvider);
    state = await AsyncValue.guard(() async {
      await scan(bytes);
      return ref.read(_getAllDocumentsProvider).call();
    });
  }

  Future<void> addPageToDocument(String documentId, Uint8List bytes) async {
    final addPages = ref.watch(_addPagesToDocumentProvider);
    await addPages(documentId, bytes);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    final delete = ref.watch(_deleteDocumentProvider);
    await delete(id);
    ref.invalidateSelf();
  }

  Future<void> rename(String id, String newName) async {
    final rename = ref.watch(_renameDocumentProvider);
    await rename(id, newName);
    ref.invalidateSelf();
  }

  Future<File> exportToPdf() async {
    final docs = state.valueOrNull ?? [];
    if (docs.isEmpty) throw Exception('No documents to export');
    final export = ref.watch(_exportToPdfProvider);
    return export(docs);
  }
}
