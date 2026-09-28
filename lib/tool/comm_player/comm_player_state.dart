import 'package:mockingbird/db/entities/sentence.dart';
import 'package:mockingbird/tool/extensions.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

import '../../db/entities/subtitle.dart';
import '../../mobile/tab_player/subtitle/subtitle_state.dart';

abstract class CommPlayerState {
  const CommPlayerState();
}

class CommPlayerInitState extends CommPlayerState {
  const CommPlayerInitState();
}

class CommPlayerEmptyState extends CommPlayerState {
  const CommPlayerEmptyState();
}

class CommPlayerDataState extends CommPlayerState {
  final int? loopIndex;

  final bool playing;

  final String title;

  final Duration position;

  final Duration duration;

  final double volume;

  final double speed;

  final double aspectRatio;

  final AssetType mediaType;

  final bool subtitleListVisible;

  final List<Subtitle> subtitleList;

  final SubtitleState subtitleState;

  final VideoPlayerController player;

  final bool subtitleListButtonVisible;

  const CommPlayerDataState({
    required this.aspectRatio,
    required this.subtitleListButtonVisible,
    required this.subtitleList,
    required this.subtitleListVisible,
    required this.player,
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

  CommPlayerDataState copyWith({
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
    return CommPlayerDataState(
      aspectRatio: aspectRatio ?? this.aspectRatio,
      subtitleListButtonVisible: subtitleListButtonVisible ?? this.subtitleListButtonVisible,
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

  /*
  runetime copyWith, will call subclass's copyWith instead
  in CommonPlayerBloc all CommonPlayerDataState should only call this rCopyWith
  to fix the bug normal copyWith generate an CommonPlayerDataState, will elimate subclass's additional properties
  * */
  CommPlayerDataState rCopyWith({
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
  }) => copyWith(
    loopIndex: loopIndex,
    playing: playing,
    aspectRatio: aspectRatio,
    volume: volume,
    speed: speed,
    subtitleState: subtitleState,
    mediaType: mediaType,
    subtitleListVisible: subtitleListVisible,
    subtitleListButtonVisible: subtitleListButtonVisible,
    position: position,
    duration: duration,
    title: title,
    subtitleList: subtitleList,
  );

  Subtitle? get subtitle => subtitleState.as<SubtitleDataState>()?.subtitle;
  Sentence? get playingSentence => subtitle?.sentenceList.spot(position)?.sentence;
}
