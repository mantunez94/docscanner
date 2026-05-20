import '../../domain/entities/scanned_document.dart';
import '../../domain/repositories/document_repository.dart';
import '../datasources/local_datasource.dart';
import '../models/scanned_document_model.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final LocalDataSource dataSource;

  DocumentRepositoryImpl(this.dataSource);

  @override
  Future<List<ScannedDocument>> getAll() async {
    final models = await dataSource.loadAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ScannedDocument> save(ScannedDocument document) async {
    final model = ScannedDocumentModel.fromEntity(document);
    await dataSource.save(model);
    return model.toEntity();
  }

  @override
  Future<void> delete(String id) async {
    await dataSource.delete(id);
  }

  @override
  Future<ScannedDocument> rename(String id, String newName) async {
    final model = await dataSource.rename(id, newName);
    return model.toEntity();
  }
}
