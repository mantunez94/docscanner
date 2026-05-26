import 'package:gal/gal.dart';
import '../../domain/repositories/gallery_saver.dart';

class GalleryService implements GallerySaver {
  Future<void> saveToGallery(String path) async {
    await Gal.putImage(path, album: 'DocScanner');
  }
}
