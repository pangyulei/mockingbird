import 'package:collection/collection.dart';
import 'package:mockingbird/db/entities/sentence.dart';
import 'package:mockingbird/db/entities/subtitle.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:video_player/video_player.dart';

sealed class MobilePlayerState {
  const MobilePlayerState();
}

class MobilePlayerInitState extends MobilePlayerState {
  const MobilePlayerInitState();
}

class MobilePlayerEmptyState extends MobilePlayerState {
  const MobilePlayerEmptyState();
}

//TODO use mixin refactor mobile and desktop
class MobilePlayerDataState extends MobilePlayerState {
  final int? loopIndex;
  final bool playing;
  final String title;
  final Duration position;
  final Duration duration;
  final double volume;
  final double speed;
  final double aspectRatio;
  final bool volumeSliderVisible;
  final AssetType mediaType;
  final bool subtitleListVisible;
  final List<Subtitle> subtitleList;
  final PlayerSubtitleState subtitleState;
  final VideoPlayerController player;
  final ItemScrollController scroller;
  final bool subtitleListButtonVisible;

  const MobilePlayerDataState({
    required this.aspectRatio,
    required this.subtitleListButtonVisible,
    required this.subtitleList,
    required this.subtitleListVisible,
    required this.scroller,
    required this.player,
    required this.volumeSliderVisible,
    required this.loopIndex,
    required this.playing,
    required this.subtitleState,
    required this.position,
    required this.duration,
    required this.volume,
    required this.speed,
    required this.mediaType,
    required this.title,
  });

  MobilePlayerDataState copyWith({
    int? Function()? loopIndex,
    bool? playing,
    double? aspectRatio,
    double? volume,
    double? speed,
    PlayerSubtitleState? subtitleState,
    AssetType? mediaType,
    bool? volumeSliderVisible,
    bool? subtitleListVisible,
    bool? subtitleListButtonVisible,
    String? Function()? selectedSubtitleName,
    Duration? position,
    Duration? duration,
    String? title,
    List<Subtitle>? subtitleList,
  }) {
    return MobilePlayerDataState(
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
      volumeSliderVisible: volumeSliderVisible ?? this.volumeSliderVisible,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      player: player,
      scroller: scroller,
    );
  }

  Subtitle? get selectedSubtitle {
    final subtitleState = this.subtitleState;
    if (subtitleState is! PlayerSubtitleDataState) return null;
    return subtitleList.firstWhereOrNull((s) => s.name == subtitleState.subtitleName);
  }
}

sealed class PlayerSubtitleState {
  const PlayerSubtitleState();
}

class PlayerSubtitleEmptyState extends PlayerSubtitleState {
  const PlayerSubtitleEmptyState();
}

class PlayerSubtitleDataState extends PlayerSubtitleState {
  final String subtitleName;
  final List<SentenceEntity> sentenceList;
  final double initialAlignment;
  final int initialIndex;

  const PlayerSubtitleDataState({
    required this.subtitleName,
    required this.sentenceList,
    required this.initialAlignment,
    required this.initialIndex,
  });
}
