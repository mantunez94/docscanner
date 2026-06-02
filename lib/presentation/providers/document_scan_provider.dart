import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/di/providers.dart';
import 'document_provider.dart';

class DocumentScan {
  DocumentScan(this._ref);
  final Ref _ref;

  Future<void> scanFromBytes(Uint8List bytes) async {
    try {
      final service = _ref.read(documentScanServiceProvider);
      await service.scanFromBytes(bytes);
      _ref.invalidate(documentListProvider);
    } catch (e) {
      _ref.read(documentListProvider.notifier).setError(e, StackTrace.current);
    }
  }

  Future<void> scanFromMultipleBytes(List<Uint8List> bytesList, [String? name]) async {
    try {
      final service = _ref.read(documentScanServiceProvider);
      await service.scanFromMultipleBytes(bytesList, name: name);
      _ref.invalidate(documentListProvider);
    } catch (e) {
      _ref.read(documentListProvider.notifier).setError(e, StackTrace.current);
    }
  }
}

final documentScanProvider = Provider<DocumentScan>((ref) => DocumentScan(ref));
