import 'dart:typed_data';

abstract class FileStorage {
  Future<String> savePageImage(String id, Uint8List bytes);
  Future<String> savePageImageWithSuffix(String documentId, Uint8List bytes);
  Future<String> saveThumbnail(String id, Uint8List bytes);
}
