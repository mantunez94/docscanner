import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local_datasource.dart';
import '../../data/repositories/document_repository_impl.dart';
import '../../domain/entities/scanned_document.dart';
import '../../domain/repositories/document_repository.dart';
import '../../domain/usecases/delete_document.dart';
import '../../domain/usecases/get_all_documents.dart';
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

  Future<void> scan(String imagePath) async {
    state = const AsyncLoading();
    final scan = ref.watch(_scanDocumentProvider);
    state = await AsyncValue.guard(() async {
      await scan(imagePath);
      return ref.read(_getAllDocumentsProvider).call();
    });
  }

  Future<void> delete(String id) async {
    final delete = ref.watch(_deleteDocumentProvider);
    await delete(id);
    ref.invalidateSelf();
  }
}
