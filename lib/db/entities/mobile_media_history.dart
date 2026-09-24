
import 'package:objectbox/objectbox.dart';

@Entity()
class MobileMediaHistory {
  @Id()
  int id;
  final String mediaId;
  final String? subtitlePath;
  final int positionMs;

  MobileMediaHistory({
    required this.mediaId,
    this.id = 0,
    this.subtitlePath,
    this.positionMs = 0,
  });

  MobileMediaHistory copyWith({
    String? Function()? subtitlePath,
    int? positionMs,
    String? mediaId,
  }) {
    return MobileMediaHistory(
      id: id,
      subtitlePath: subtitlePath == null ? this.subtitlePath : subtitlePath(),
      positionMs: positionMs ?? this.positionMs,
      mediaId: mediaId ?? this.mediaId,
    );
  }

  Duration get position => Duration(milliseconds: positionMs);

  @override
  String toString() {
    return 'MediaProgressEntity(id: $id, mediaId: $mediaId, subtitleName: $subtitlePath, positionMs: $positionMs)';
  }
}
