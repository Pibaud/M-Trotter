import 'dart:typed_data';

class Photo {
  final int id;
  final Uint8List imageData;
  final String? tag;
  final int? idAvis;
  final int? vote;

  Photo({required this.id, required this.imageData, this.tag, this.idAvis, this.vote});
}
