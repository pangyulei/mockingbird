import 'package:objectbox/objectbox.dart';

import 'desktop_media_history.dart';

@Entity()
class DesktopMetadata {
  @Id()
  int id;

  final historyList = ToMany<DesktopMediaHistory>();
  final int dbVersion;
  final String? playingMediaPath;

  DesktopMetadata({
    this.id = 0,
    this.playingMediaPath,
    this.dbVersion = 0,
  });

  DesktopMetadata copyWith({
    String? Function()? playingMediaPath,
    int? dbVersion,
  }) {
    final metadata = DesktopMetadata(
      id: id,
      dbVersion: dbVersion ?? this.dbVersion,
      playingMediaPath: playingMediaPath == null ? this.playingMediaPath : playingMediaPath(),
    );
    metadata.historyList.addAll(historyList);
    return metadata;
  }

  DesktopMetadata incDBVersion() {
    return copyWith(dbVersion: dbVersion + 1);
  }

  @override
  String toString() {
    final historyDesc = historyList.map((mp) => mp.toString()).join(',');
    return 'DesktopMetadata(id: $id, dbVersion: $dbVersion, playingMediaPath: $playingMediaPath, historyList: [$historyDesc])';
  }
}
