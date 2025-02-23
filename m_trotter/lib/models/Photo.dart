import 'dart:typed_data';

class Photo {
  final Uint8List imageData;
  final String? tag;

  Photo({required this.imageData, this.tag});
}