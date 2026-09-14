
import 'package:objectbox/objectbox.dart';

@Entity()
class MobileMediaHistory {
  @Id()
  int id;
  final String mediaId;
  final String? subtitleName;
  final int positionMs;

  MobileMediaHistory({
    required this.mediaId,
    this.id = 0,
    this.subtitleName,
    this.positionMs = 0,
  });

  MobileMediaHistory copyWith({
    String? Function()? subtitleName,
    int? positionMs,
    String? mediaId,
  }) {
    return MobileMediaHistory(
      id: id,
      subtitleName: subtitleName == null ? this.subtitleName : subtitleName(),
      positionMs: positionMs ?? this.positionMs,
      mediaId: mediaId ?? this.mediaId,
    );
  }

  Duration get position => Duration(milliseconds: positionMs);

  @override
  String toString() {
    return 'MediaProgressEntity(id: $id, mediaId: $mediaId, subtitleName: $subtitleName, positionMs: $positionMs)';
  }
}
