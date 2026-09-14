import 'package:collection/collection.dart';
import 'package:mockingbird/objectbox.g.dart';

import '../tool/extensions.dart';
import 'entities/mobile_media_history.dart';
import 'entities/mobile_metadata.dart';
import 'entities/mobile_preference.dart';

class MobileDB {
  static late final Store _store;
  static Future<void> init() async {
    _store = await initDB();
  }
  
  static Future<MobileMetadata> loadMetadata() async {
    return (await _store.box<MobileMetadata>().getAllAsync()).firstOrNull ??
        MobileMetadata();
  }

  static Future<MobileMetadata> updateMetadata(MobileMetadata metadata) async {
    return await _store.box<MobileMetadata>().putAndGetAsync(metadata);
  }

  static Future<MobileMediaHistory> updateHistory(MobileMediaHistory progress) async {
    return await _store.box<MobileMediaHistory>().putAndGetAsync(progress);
  }

  static Future<MobilePreference?> loadPreference() async {
    return (await _store.box<MobilePreference>().getAllAsync()).firstOrNull;
  }

  static Future<MobilePreference> updatePreference(
    MobilePreference preference,
  ) async {
    return await _store.box<MobilePreference>().putAndGetAsync(preference);
  }

  // ({List<MF_SF> mfsfList, List<M_SF> msfList}) _processMediaSubtitleFiles(
  //   List<EnMedia> albumMedias,
  //   List<File> files,
  // ) {
  //   final List<File> videoFiles = [];
  //   final List<File> audioFiles = [];
  //   final List<File> subtitleFiles = [];
  //   for (var f in files) {
  //     final ext = p.extension(f.path).replaceFirst('.', '').toLowerCase();
  //     if (kVideoExtensions.contains(ext)) videoFiles.add(f);
  //     if (kAudioExtensions.contains(ext)) audioFiles.add(f);
  //     if (kSubtitleExtensions.contains(ext)) subtitleFiles.add(f);
  //   }
  //   final mfsfList = [...videoFiles, ...audioFiles].map((mf) {
  //     final mediaName = p.basenameWithoutExtension(mf.path);
  //     final subtitleFile = subtitleFiles.firstWhereOrNull((sf) {
  //       final subtitleName = p.basenameWithoutExtension(sf.path);
  //       return subtitleName.contains(mediaName);
  //     });
  //     return (mediaFile: mf, subtitleFile: subtitleFile);
  //   }).toList();

  //   //deal with unmatched subtitles
  //   final matchedSubtitlePaths = mfsfList
  //       .map((mfsf) => mfsf.subtitleFile)
  //       .whereType<File>()
  //       .map((sf) => sf.path)
  //       .toSet();
  //   final unmatchedSubtitleFiles = subtitleFiles.where(
  //     (sf) => !matchedSubtitlePaths.contains(sf.path),
  //   );
  //   final mediasWithoutSubtitle = albumMedias.where(
  //     (m) => m.subtitleList.isEmpty,
  //   );
  //   final msfList = mediasWithoutSubtitle
  //       .map((m) {
  //         final subtitleFile = unmatchedSubtitleFiles.firstWhereOrNull((sf) {
  //           final subtitleName = p.basenameWithoutExtension(sf.path);
  //           return subtitleName.contains(m.name);
  //         });
  //         return (media: m, subtitleFile: subtitleFile);
  //       })
  //       .whereType<M_SF>()
  //       .toList();
  //   return (mfsfList: mfsfList, msfList: msfList);
  // }

  // Future<List<EnMedia>> _mediasMadeFromMFSFList(
  //   EnAlbum album,
  //   List<MF_SF> mfsfList,
  // ) async {
  //   if (mfsfList.isEmpty) return [];

  //   final appDir = await getApplicationDocumentsDirectory();
  //   final mediaDir = Directory(p.join(appDir.path, 'medias'));
  //   if (!await mediaDir.exists()) {
  //     await mediaDir.create(recursive: true);
  //   }

  //   // save read media files to app dir
  //   final saveMediasToDir = mfsfList.asMap().entries.map((e) {
  //     final i = e.key;
  //     final timestamp = DateTime.now().microsecondsSinceEpoch;
  //     final uniqueName = "${timestamp}_$i";
  //     final mediaFile = e.value.mediaFile;
  //     return mediaFile.copy(
  //       p.join(mediaDir.path, "$uniqueName${p.extension(mediaFile.path)}"),
  //     );
  //   });
  //   final dirMediaFiles = await Future.wait(saveMediasToDir);
  //   final makeSubtitles = mfsfList.map((mfsf) {
  //     final subtitleFile = mfsf.subtitleFile;
  //     return subtitleFile == null
  //         ? Future.value(null)
  //         : SubtitleParser.parseFile(subtitleFile);
  //   });
  //   final subtitlesWithoutId = await Future.wait(makeSubtitles);
  //   //construct media models, prepared for save them to db
  //   final mediasWithoutId = dirMediaFiles.asMap().entries.map((e) {
  //     int i = e.key;
  //     final dirMediaFile = e.value;
  //     final mediaName = p.basenameWithoutExtension(mfsfList[i].mediaFile.path);
  //     final media = EnMedia(path: dirMediaFile.path, name: mediaName, id: 0);
  //     media.albumList.add(album);
  //     final subtitle = subtitlesWithoutId[i];
  //     if ((subtitle != null)) {
  //       media.subtitleList.add(subtitle);
  //     }
  //     return media;
  //   }).toList();
  //   return mediasWithoutId;
  // }

  // Future<List<EnMedia>> _mediasFilledSubtitleFromMSFList(
  //   EnAlbum album,
  //   List<M_SF> msfList,
  // ) async {
  //   if (msfList.isEmpty) return [];
  //   final makeSubtitles = msfList
  //       .map((msf) => msf.subtitleFile)
  //       .map((sf) => SubtitleParser.parseFile(sf));
  //   final subtitlesWithoutId = await Future.wait(makeSubtitles);
  //   final mediasFilledSubtitle = msfList.asMap().entries.map((e) {
  //     int i = e.key;
  //     final media = e.value.media;
  //     final subtitleWithoutId = subtitlesWithoutId[i];
  //     if (subtitleWithoutId != null) {
  //       media.subtitleList.clear();
  //       media.subtitleList.add(subtitleWithoutId);
  //     }
  //     return media;
  //   }).toList();
  //   return mediasFilledSubtitle;
  // }

  // Future<void> importMediaAndSubtitles(EnAlbum album, List<File> files) async {
  //   if (files.isEmpty) return;
  //   final (:mfsfList, :msfList) = _processMediaSubtitleFiles(
  //     album.mediaList,
  //     files,
  //   );
  //   final mediasMade = await _mediasMadeFromMFSFList(album, mfsfList);
  //   final mediasFilled = await _mediasFilledSubtitleFromMSFList(album, msfList);
  //   await Database.store.box<EnMedia>().putAndGetManyAsync([
  //     ...mediasMade,
  //     ...mediasFilled,
  //   ]);
  // }

  // Future<EnMedia> updateMedia(
  //   EnMedia media, {
  //   String? name,
  //   Subtitle? Function()? subtitle,
  // }) async {
  //   if (name == null && subtitle == null) return media;
  //   final updatedMedia = await Database.store.runInTransactionAsync<EnMedia, int>(
  //     TxMode.write,
  //     (Store store, int mediaId) {
  //       final mediaBox = store.box<EnMedia>();
  //       final media = mediaBox.get(mediaId);
  //       if (media == null) {
  //         throw ArgumentError('mediaId $mediaId not existed');
  //       }
  //       final subtitleBox = store.box<Subtitle>();
  //       final sentenceBox = store.box<SentenceEntity>();

  //       EnMedia updatedMedia = media.copyWith();
  //       if (name != null) {
  //         //want to update name
  //         final trimmedNewName = name.trim();
  //         if (trimmedNewName.isNotEmpty && trimmedNewName != media.name) {
  //           updatedMedia = updatedMedia.copyWith(name: trimmedNewName);
  //         }
  //       }
  //       if (subtitle != null) {
  //         //want to update subtitle
  //         final subtitleList = media.subtitleList;
  //         final sentenceList = subtitleList
  //             .map((st) => st.sentenceList)
  //             .flattenedToList;
  //         final subtitleIdList = [for (final sub in subtitleList) sub.id];
  //         final sentenceIdList = [for (final sen in sentenceList) sen.id];
  //         sentenceBox.removeMany(sentenceIdList);
  //         subtitleBox.removeMany(subtitleIdList);

  //         final newSubtitle = subtitle();
  //         final newSubtitleList = newSubtitle == null
  //             ? <Subtitle>[]
  //             : [newSubtitle];
  //         updatedMedia = updatedMedia.copyWith(subtitleList: newSubtitleList);
  //       }
  //       mediaBox.put(updatedMedia);
  //       return updatedMedia;
  //     },
  //     media.id,
  //   );
  //   return updatedMedia;
  // }

  // Future<void> deleteMedia(EnMedia media) async {
  //   await Database.store.runInTransactionAsync<void, int>(TxMode.write, (
  //     Store store,
  //     int mediaId,
  //   ) {
  //     final mediaBox = store.box<EnMedia>();
  //     final media = mediaBox.get(mediaId);
  //     if (media == null) {
  //       return;
  //     }
  //     final subtitleBox = store.box<Subtitle>();
  //     final sentenceBox = store.box<SentenceEntity>();

  //     final subtitleList = media.subtitleList;
  //     final sentenceList = subtitleList
  //         .map((st) => st.sentenceList)
  //         .flattenedToList;
  //     final subtitleIdList = [for (final sub in subtitleList) sub.id];
  //     final sentenceIdList = sentenceList.map((sen) => sen.id).toList();
  //     mediaBox.remove(mediaId);
  //     subtitleBox.removeMany(subtitleIdList);
  //     sentenceBox.removeMany(sentenceIdList);
  //   }, media.id);

  //   // Remove file
  //   final file = File(media.path);
  //   if (await file.exists()) {
  //     await file.delete();
  //   }
  // }

  // Future<Directory> get _albumCoversDir async {
  //   final appDir = await getApplicationDocumentsDirectory();
  //   return Directory(p.join(appDir.path, 'album_covers'));
  // }

  // Future<String> _newAlbumCoverPath() async {
  //   final coversDir = await _albumCoversDir;
  //   if (!await coversDir.exists()) {
  //     await coversDir.create(recursive: true);
  //   }
  //   // Generate a unique filename using timestamp and original extension
  //   final String fileName = '${DateTime.now().millisecondsSinceEpoch}';
  //   return p.join(coversDir.path, fileName);
  // }

  // Future<SentenceEntity?> loadSentence(int? id) async {
  //   if (id == null) return null;
  //   return await Database.store.box<SentenceEntity>().getAsync(id);
  // }

  // Future<EnAlbum?> createAlbum(String name, {File? cover}) async {
  //   //校验 name
  //   final trimmedName = name.trim();
  //   if (trimmedName.isEmpty) {
  //     return null;
  //   }

  //   //保存封面
  //   final String? coverPath;
  //   if (cover != null) {
  //     coverPath = await _newAlbumCoverPath();
  //     await cover.copy(coverPath);
  //   } else {
  //     coverPath = null;
  //   }
  //   //获取 最大SortOrder
  //   final maxSortOrder = await _albumMaxSortOrder;
  //   final sortOrder = maxSortOrder == null ? 0 : maxSortOrder + 1;
  //   return await Database.store.box<EnAlbum>().putAndGetAsync(
  //     EnAlbum(name: trimmedName, sortOrder: sortOrder, cover: coverPath, id: 0),
  //   );
  // }

  // Future<int?> get _albumMinSortOrder async {
  //   final albumBox = Database.store.box<EnAlbum>();
  //   final query = albumBox.query().order(EnAlbum_.sortOrder).build();
  //   query.limit = 1;
  //   final minSortOrder = (await query.findFirstAsync())?.sortOrder;
  //   query.close();
  //   return minSortOrder;
  // }

  // Future<int?> get _albumMaxSortOrder async {
  //   final albumBox = Database.store.box<EnAlbum>();
  //   final query = albumBox
  //       .query()
  //       .order(EnAlbum_.sortOrder, flags: Order.descending)
  //       .build();
  //   query.limit = 1;
  //   final maxSortOrder = (await query.findFirstAsync())?.sortOrder;
  //   query.close();
  //   return maxSortOrder;
  // }

  // Future<EnAlbum> sortAlbumToFirst(EnAlbum album) async {
  //   final maxSortOrder = await _albumMaxSortOrder;
  //   final sortOrder = maxSortOrder == null ? 0 : maxSortOrder + 1;
  //   return await updateAlbum(album, sortOrder: sortOrder);
  // }

  // Future<EnAlbum> sortAlbumToLast(EnAlbum album) async {
  //   final minSortOrder = await _albumMinSortOrder;
  //   final sortOrder = minSortOrder == null ? 0 : minSortOrder - 1;
  //   return await updateAlbum(album, sortOrder: sortOrder);
  // }

  // Future<EnAlbum> updateAlbum(
  //   EnAlbum album, {
  //   String? name,
  //   File? Function()? coverFunc,
  //   int? sortOrder,
  // }) async {
  //   EnAlbum updatedAlbum = album.copyWith();
  //   if (name != null) {
  //     //update name
  //     final trimmedName = name.trim();
  //     if (trimmedName.isNotEmpty && trimmedName != album.name) {
  //       updatedAlbum = updatedAlbum.copyWith(name: trimmedName);
  //     }
  //   }
  //   if (coverFunc != null) {
  //     //update cover
  //     final newCover = coverFunc();
  //     if (newCover == null) {
  //       //remove cover
  //       updatedAlbum = await _deleteAlbumCoverFile(updatedAlbum);
  //     } else if (newCover.path != album.cover) {
  //       //update to newcover
  //       updatedAlbum = await _deleteAlbumCoverFile(updatedAlbum);
  //       final newCoverPath = await _newAlbumCoverPath();
  //       await newCover.copy(newCoverPath);
  //       updatedAlbum = updatedAlbum.copyWith(cover: () => newCoverPath);
  //     }
  //   }
  //   if (sortOrder != null) {
  //     //want to update sortOrder
  //     updatedAlbum = updatedAlbum.copyWith(sortOrder: sortOrder);
  //   }
  //   if (updatedAlbum.cover != album.cover ||
  //       updatedAlbum.name != album.name ||
  //       updatedAlbum.sortOrder != album.sortOrder) {
  //     return await Database.store.box<EnAlbum>().putAndGetAsync(updatedAlbum);
  //   } else {
  //     return album;
  //   }
  // }

  // Future<EnAlbum> _deleteAlbumCoverFile(EnAlbum album) async {
  //   if (album.cover != null) {
  //     final oldCover = File(album.cover!);
  //     if (await oldCover.exists()) {
  //       await oldCover.delete();
  //     }
  //     return album.copyWith(cover: () => null);
  //   } else {
  //     return album;
  //   }
  // }

  // Future<List<int>> loadAlbumIdList() async {
  //   return (await loadAlbums()).map((a) => a.id).toList();
  // }

  // Future<List<EnAlbum>> loadAlbums() async {
  //   final query = Database.store
  //       .box<EnAlbum>()
  //       .query()
  //       .order(EnAlbum_.sortOrder, flags: Order.descending)
  //       .build();
  //   final result = await query.findAsync();
  //   query.close();
  //   return result;
  // }

  // Future<EnAlbum?> loadAlbum(int id) async {
  //   final album = await Database.store.box<EnAlbum>().getAsync(id);
  //   album?.sortMedias();
  //   return album;
  // }

  // Future<(EnAlbum, EnAlbum)> swapAlbumsOrder(
  //   EnAlbum aAlbum,
  //   EnAlbum bAlbum,
  // ) async {
  //   final aSortOrder = aAlbum.sortOrder;
  //   aAlbum = aAlbum.copyWith(sortOrder: bAlbum.sortOrder);
  //   bAlbum = bAlbum.copyWith(sortOrder: aSortOrder);
  //   await Database.store.box<EnAlbum>().putManyAsync([aAlbum, bAlbum]);
  //   return (aAlbum, bAlbum);
  // }

  // Future<void> deleteAlbum(EnAlbum album) async {
  //   await deleteAlbums([album]);
  // }

  // Future<void> deleteAlbums(List<EnAlbum> albums) async {
  //   if (albums.isEmpty) return;
  //   albums = albums.where((a) => a.id > 0).toList();

  //   await Database.store.runInTransactionAsync(TxMode.write, (
  //     Store store,
  //     List<int> albumIdList,
  //   ) {
  //     final mediaBox = store.box<EnMedia>();
  //     final subtitleBox = store.box<Subtitle>();
  //     final sentenceBox = store.box<SentenceEntity>();
  //     final albumBox = store.box<EnAlbum>();

  //     final albumIdsSet = albumIdList.toSet();
  //     final mediaList = mediaBox
  //         .getAll()
  //         .map((m) {
  //           m.albumList.removeWhere((a) => albumIdsSet.contains(a.id));
  //           return m;
  //         })
  //         .where((m) => m.albumList.isEmpty)
  //         .toList();
  //     final mediaIdList = mediaList.map((m) => m.id).toList();
  //     final subtitleList = mediaList.map((m) => m.subtitleList).flattenedToList;
  //     final subtitleIdList = subtitleList.map((s) => s.id).toList();
  //     final sentenceList = subtitleList
  //         .map((st) => st.sentenceList)
  //         .flattenedToList;
  //     final sentenceIdList = sentenceList.map((s) => s.id).toList();
  //     albumBox.removeMany(albumIdList);
  //     mediaBox.removeMany(mediaIdList);
  //     subtitleBox.removeMany(subtitleIdList);
  //     sentenceBox.removeMany(sentenceIdList);
  //   }, [for (final a in albums) a.id]);

  //   // Delete cover files for removed playlists
  //   final uselessCovers = albums
  //       .where((a) => a.cover != null)
  //       .map((a) => File(a.cover!));

  //   final removeCovers = uselessCovers.map((cover) async {
  //     if (await cover.exists()) {
  //       await cover.delete();
  //     }
  //   });
  //   await Future.wait(removeCovers);
  // }

  // Future<EnMedia?> loadMedia(int id) async {
  //   return await Database.store.box<EnMedia>().getAsync(id);
  // }
}

// extension on EnAlbum {
//   void sortMedias() {
//     mediaList.sort(
//       (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
//     );
//   }
// }
