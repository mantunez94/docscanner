import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/local_datasource.dart';
import '../repositories/document_repository_impl.dart';
import '../services/file_service.dart';
import '../services/pdf_service.dart';
import '../services/gallery_service.dart';
import '../../domain/repositories/document_repository.dart';
import '../../domain/repositories/file_storage.dart';
import '../../domain/repositories/pdf_generator.dart';
import '../../domain/repositories/gallery_saver.dart';
import '../../domain/usecases/add_pages_to_document.dart';
import '../../domain/usecases/delete_document.dart';
import '../../domain/usecases/export_to_pdf.dart';
import '../../domain/usecases/get_all_documents.dart';
import '../../domain/usecases/remove_page_from_document.dart';
import '../../domain/usecases/rename_document.dart';
import '../../domain/usecases/scan_document.dart';

final repositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepositoryImpl(LocalDataSource());
});

final fileServiceProvider = Provider<FileStorage>((ref) {
  return FileService();
});

final pdfServiceProvider = Provider<PdfGenerator>((ref) {
  return PdfService();
});

final galleryServiceProvider = Provider<GallerySaver>((ref) {
  return GalleryService();
});

final scanDocumentProvider = Provider<ScanDocument>((ref) {
  return ScanDocument(ref.watch(repositoryProvider));
});

final getAllDocumentsProvider = Provider<GetAllDocuments>((ref) {
  return GetAllDocuments(ref.watch(repositoryProvider));
});

final deleteDocumentProvider = Provider<DeleteDocument>((ref) {
  return DeleteDocument(ref.watch(repositoryProvider));
});

final renameDocumentProvider = Provider<RenameDocument>((ref) {
  return RenameDocument(ref.watch(repositoryProvider));
});

final exportToPdfProvider = Provider<ExportToPdf>((ref) {
  return ExportToPdf(ref.watch(repositoryProvider));
});

final addPagesToDocumentProvider = Provider<AddPagesToDocument>((ref) {
  return AddPagesToDocument(ref.watch(repositoryProvider));
});

final removePageFromDocumentProvider = Provider<RemovePageFromDocument>((ref) {
  return RemovePageFromDocument(ref.watch(repositoryProvider));
});
