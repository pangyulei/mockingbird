import 'package:objectbox/objectbox.dart';

import 'mobile_media_history.dart';

@Entity()
class MobileMetadata {
  @Id()
  int id;

  final historyList = ToMany<MobileMediaHistory>();
  final int dbVersion;
  final String? playingMediaId;
  final bool permissionRequested;

  MobileMetadata({
    this.id = 0,
    this.playingMediaId,
    this.dbVersion = 0,
    this.permissionRequested = false,
  });

  MobileMetadata copyWith({
    String? Function()? playingMediaId,
    int? dbVersion,
    bool? permissionRequested,
  }) {
    final metadata = MobileMetadata(
      id: id,
      dbVersion: dbVersion ?? this.dbVersion,
      permissionRequested: permissionRequested ?? this.permissionRequested,
      playingMediaId: playingMediaId == null ? this.playingMediaId : playingMediaId(),
    );
    metadata.historyList.addAll(historyList);
    return metadata;
  }

  MobileMetadata incDBVersion() {
    return copyWith(dbVersion: dbVersion + 1);
  }

  @override
  String toString() {
    final historyDesc = historyList.map((mp) => mp.toString()).join(',');
    return 'MobileMetadata(id: $id, dbVersion: $dbVersion, playingMediaId: $playingMediaId, permissionRequested: $permissionRequested, historyList: [$historyDesc])';
  }
}
