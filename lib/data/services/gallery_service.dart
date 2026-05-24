import 'package:gal/gal.dart';

class GalleryService {
  Future<void> saveToGallery(String path) async {
    await Gal.putImage(path, album: 'DocScanner');
  }
}
