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
    _cache[index] = _cache[index].copyWith(name: newName);
    await _persist();
    return _cache[index];
  }

  Future<ScannedDocumentModel> addPages(
    String id,
    List<String> newPages, [
    String? pdfPath,
  ]) async {
    final index = _cache.indexWhere((d) => d.id == id);
    if (index == -1) throw Exception('Document not found');
    final existing = _cache[index];
    final allPages = [...existing.pages, ...newPages];
    _cache[index] = existing.copyWith(
      filePath: allPages.first,
      pages: allPages,
      pdfPath: pdfPath,
    );
    await _persist();
    return _cache[index];
  }

  Future<ScannedDocumentModel> removePage(String id, String pagePath) async {
    final index = _cache.indexWhere((d) => d.id == id);
    if (index == -1) throw Exception('Document not found');
    final existing = _cache[index];
    final remaining = existing.pages.where((p) => p != pagePath).toList();
    if (remaining.isEmpty) throw Exception('Cannot remove the last page');
    _cache[index] = existing.copyWith(
      filePath: remaining.first,
      pages: remaining,
    );
    await _persist();
    return _cache[index];
  }

  Future<void> updatePdfPath(String id, String pdfPath) async {
    final index = _cache.indexWhere((d) => d.id == id);
    if (index == -1) throw Exception('Document not found');
    _cache[index] = _cache[index].copyWith(pdfPath: pdfPath);
    await _persist();
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
