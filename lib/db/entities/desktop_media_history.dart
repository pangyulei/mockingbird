
import 'package:objectbox/objectbox.dart';

@Entity()
class DesktopMediaHistory {
  @Id()
  int id;
  final String mediaPath;
  final String? subtitleName;
  final int positionMs;

  DesktopMediaHistory({
    required this.mediaPath,
    this.id = 0,
    this.subtitleName,
    this.positionMs = 0,
  });

  DesktopMediaHistory copyWith({
    String? Function()? subtitleName,
    int? positionMs,
    String? mediaPath,
  }) {
    return DesktopMediaHistory(
      id: id,
      subtitleName: subtitleName == null ? this.subtitleName : subtitleName(),
      positionMs: positionMs ?? this.positionMs,
      mediaPath: mediaPath ?? this.mediaPath,
    );
  }

  Duration get position => Duration(milliseconds: positionMs);

  @override
  String toString() {
    return 'MediaProgressEntity(id: $id, mediaPath: $mediaPath, subtitleName: $subtitleName, positionMs: $positionMs)';
  }
}
