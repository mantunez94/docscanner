import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final dir = Directory('assets/icon');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  final image = img.Image(width: 1024, height: 1024);
  img.fill(image, color: img.ColorRgb8(63, 81, 181));

  img.drawRect(image, x1: 340, y1: 320, x2: 440, y2: 700, color: img.ColorRgba8(255, 255, 255, 255));
  img.drawRect(image, x1: 340, y1: 320, x2: 480, y2: 370, color: img.ColorRgba8(255, 255, 255, 255));
  img.drawRect(image, x1: 340, y1: 660, x2: 480, y2: 700, color: img.ColorRgba8(255, 255, 255, 255));

  img.drawRect(image, x1: 520, y1: 320, x2: 660, y2: 370, color: img.ColorRgba8(255, 255, 255, 255));
  img.drawRect(image, x1: 520, y1: 320, x2: 570, y2: 500, color: img.ColorRgba8(255, 255, 255, 255));
  img.drawRect(image, x1: 520, y1: 480, x2: 660, y2: 530, color: img.ColorRgba8(255, 255, 255, 255));
  img.drawRect(image, x1: 610, y1: 520, x2: 660, y2: 680, color: img.ColorRgba8(255, 255, 255, 255));
  img.drawRect(image, x1: 520, y1: 650, x2: 660, y2: 700, color: img.ColorRgba8(255, 255, 255, 255));

  File('assets/icon/icon.png').writeAsBytesSync(img.encodePng(image));
  print('Icon created at assets/icon/icon.png');
}
