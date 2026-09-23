import 'package:collection/collection.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

import '../../db/entities/subtitle.dart';
import '../../mobile/tab_player/subtitle/subtitle_state.dart';

abstract interface class CommPlayerDataStateITF {
  int? get loopIndex;
  bool get playing;
  String get title;
  Duration get position;
  Duration get duration;
  double get volume;
  double get speed;
  double get aspectRatio;
  AssetType get mediaType;
  bool get subtitleListVisible;
  List<Subtitle> get subtitleList;
  SubtitleState get subtitleState;
  VideoPlayerController get player;
  bool get subtitleListButtonVisible;
}

mixin CommPlayerDataStateImpl<T extends CommPlayerDataStateITF>
    on CommPlayerDataStateITF {
  T commCreate({
    required int? loopIndex,
    required bool playing,
    required String title,
    required Duration position,
    required Duration duration,
    required double volume,
    required double speed,
    required double aspectRatio,
    required AssetType mediaType,
    required bool subtitleListVisible,
    required List<Subtitle> subtitleList,
    required SubtitleState subtitleState,
    required VideoPlayerController player,
    required bool subtitleListButtonVisible,
  });

  T commCopyWith({
    int? Function()? loopIndex,
    bool? playing,
    double? aspectRatio,
    double? volume,
    double? speed,
    SubtitleState? subtitleState,
    AssetType? mediaType,
    bool? subtitleListVisible,
    bool? subtitleListButtonVisible,
    Duration? position,
    Duration? duration,
    String? title,
    List<Subtitle>? subtitleList,
  }) {
    return commCreate(
      aspectRatio: aspectRatio ?? this.aspectRatio,
      subtitleListButtonVisible:
          subtitleListButtonVisible ?? this.subtitleListButtonVisible,
      subtitleList: subtitleList ?? this.subtitleList,
      subtitleListVisible: subtitleListVisible ?? this.subtitleListVisible,
      loopIndex: loopIndex == null ? this.loopIndex : loopIndex(),
      playing: playing ?? this.playing,
      title: title ?? this.title,
      mediaType: mediaType ?? this.mediaType,
      subtitleState: subtitleState ?? this.subtitleState,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      player: player,
    );
  }

  Subtitle? get selectedSubtitle {
    final subtitleState = this.subtitleState;
    if (subtitleState is! SubtitleDataState) return null;
    return subtitleList.firstWhereOrNull(
      (s) => s.name == subtitleState.subtitleName,
    );
  }
}
