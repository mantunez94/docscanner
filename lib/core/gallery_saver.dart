import 'dart:io';
import 'package:gal/gal.dart';

class GallerySaver {
  static Future<String> saveImage(String imagePath, {String? name}) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('Image not found: $imagePath');
    }

    await Gal.putImage(imagePath, album: 'DocScanner');

    final now = DateTime.now();
    final defaultName = 'DocScan_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour}${now.minute}${now.second}';
    final finalName = name ?? defaultName;

    final dir = file.parent;
    final renamedPath = '${dir.path}/$finalName.jpg';
    if (imagePath != renamedPath) {
      await file.rename(renamedPath);
    }

    return renamedPath;
  }
}
