// import 'package:objectbox/objectbox.dart';

// import 'en_album.dart';
// import 'subtitle_entity.dart';

// @Entity()
// class EnMedia {
//   @Id()
//   int id;

//   final String path; // Full path to the media file
//   final String name;
//   final albumList = ToMany<EnAlbum>();
//   @Backlink('media')
//   final subtitleList = ToMany<SubtitleEntity>();

//   //objectbox will use this default constructor
//   EnMedia({required this.path, required this.name, required this.id});

//   MediaType get type => MediaType.fromPath(path);

//   EnMedia copyWith({String? name, List<SubtitleEntity>? subtitleList}) {
//     final media = EnMedia(id: id, path: path, name: name ?? this.name);
//     media.subtitleList.addAll(subtitleList ?? this.subtitleList);
//     media.albumList.addAll(albumList);
//     return media;
//   }

//   @override
//   String toString() {
//     return 'EnMedia(id: $id, name: $name, path: $path, type: $type)';
//   }
// }

// enum MediaType {
//   audio(0),
//   video(1);

//   final int raw;

//   const MediaType(this.raw);

//   static MediaType fromPath(String path) {
//     final String extension = path.toLowerCase().split('.').last;
//     if (kVideoExtensions.contains(extension)) return MediaType.video;
//     if (kAudioExtensions.contains(extension)) return MediaType.audio;
//     throw ArgumentError('Unsupported file extension: $extension');
//   }
// }
