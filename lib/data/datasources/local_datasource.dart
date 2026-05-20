import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/scanned_document_model.dart';

class LocalDataSource {
  List<ScannedDocumentModel> _cache = [];

  Future<File> get _indexFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/documents/index.json');
  }

  Future<List<ScannedDocumentModel>> loadAll() async {
    if (_cache.isNotEmpty) return _cache;
    final file = await _indexFile;
    if (!await file.exists()) return [];
    final content = await file.readAsString();
    final list = (json.decode(content) as List)
        .map((e) => ScannedDocumentModel.fromJson(e))
        .toList();
    _cache = list;
    return list;
  }

  Future<void> save(ScannedDocumentModel model) async {
    _cache.add(model);
    await _persist();
  }

  Future<ScannedDocumentModel> rename(String id, String newName) async {
    final index = _cache.indexWhere((d) => d.id == id);
    if (index == -1) throw Exception('Document not found');
    final existing = _cache[index];
    final updated = ScannedDocumentModel(
      id: existing.id,
      filePath: existing.filePath,
      pages: existing.pages,
      thumbnailPath: existing.thumbnailPath,
      createdAt: existing.createdAt,
      name: newName,
    );
    _cache[index] = updated;
    await _persist();
    return updated;
  }

  Future<ScannedDocumentModel> addPages(String id, List<String> newPages) async {
    final index = _cache.indexWhere((d) => d.id == id);
    if (index == -1) throw Exception('Document not found');
    final existing = _cache[index];
    final allPages = [...existing.pages, ...newPages];
    final updated = ScannedDocumentModel(
      id: existing.id,
      filePath: allPages.first,
      pages: allPages,
      thumbnailPath: existing.thumbnailPath,
      createdAt: existing.createdAt,
      name: existing.name,
    );
    _cache[index] = updated;
    await _persist();
    return updated;
  }

  Future<void> delete(String id) async {
    _cache.removeWhere((d) => d.id == id);
    await _persist();
  }

  Future<void> _persist() async {
    final file = await _indexFile;
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    final content = json.encode(_cache.map((e) => e.toJson()).toList());
    await file.writeAsString(content);
  }
}
