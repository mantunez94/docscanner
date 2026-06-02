import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/di/providers.dart';
import 'document_provider.dart';

class DocumentExport {
  DocumentExport(this._ref);
  final Ref _ref;

  Future<File> exportToPdf() async {
    final docs = _ref.read(documentListProvider).valueOrNull ?? [];
    if (docs.isEmpty) throw Exception('No documents to export');
    final export = _ref.watch(exportToPdfProvider);
    final path = await export(docs);
    return File(path);
  }
}

final documentExportProvider = Provider<DocumentExport>((ref) => DocumentExport(ref));
