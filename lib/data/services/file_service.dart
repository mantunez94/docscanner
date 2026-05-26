import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../domain/repositories/file_storage.dart';

class FileService implements FileStorage {
  Future<String> get _documentsDir async {
    final dir = await getApplicationDocumentsDirectory();
    final docDir = Directory('${dir.path}/documents');
    if (!await docDir.exists()) await docDir.create(recursive: true);
    return docDir.path;
  }

  Future<String> savePageImage(String id, Uint8List bytes) async {
    final dir = await _documentsDir;
    final path = '$dir/$id.jpg';
    await File(path).writeAsBytes(bytes);
    return path;
  }

  Future<String> savePageImageWithSuffix(String documentId, Uint8List bytes) async {
    final dir = await _documentsDir;
    final pageId = DateTime.now().millisecondsSinceEpoch.toString();
    final path = '$dir/${documentId}_$pageId.jpg';
    await File(path).writeAsBytes(bytes);
    return path;
  }

  Future<String> saveThumbnail(String id, Uint8List bytes) async {
    final dir = await _documentsDir;
    final path = '$dir/${id}_thumb.jpg';
    final original = img.decodeImage(bytes);
    if (original == null) throw Exception('Failed to decode thumbnail');
    final thumb = img.copyResize(original, width: 200);
    await File(path).writeAsBytes(img.encodeJpg(thumb, quality: 65));
    return path;
  }
}
