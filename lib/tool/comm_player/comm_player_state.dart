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

mixin CommPlayerDataStateMx on CommPlayerState {
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

  CommPlayerDataStateMx create({
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

  CommPlayerDataStateMx copyWith({
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
    return create(
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
  Subtitle? get selectedSubtitle => subtitleState.as<SubtitleDataState>()?.subtitle;
}

class CommPlayerDataState extends CommPlayerState
    with CommPlayerDataStateMx {
  @override
  final int? loopIndex;
  @override
  final bool playing;
  @override
  final String title;
  @override
  final Duration position;
  @override
  final Duration duration;
  @override
  final double volume;
  @override
  final double speed;
  @override
  final double aspectRatio;
  @override
  final AssetType mediaType;
  @override
  final bool subtitleListVisible;
  @override
  final List<Subtitle> subtitleList;
  @override
  final SubtitleState subtitleState;
  @override
  final VideoPlayerController player;
  @override
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

  @override
  CommPlayerDataState copyWith({
    int? Function()? loopIndex,
    bool? playing,
    double? aspectRatio,
    double? volume,
    double? speed,
    SubtitleState? subtitleState,
    AssetType? mediaType,
    bool? volumeSliderVisible,
    bool? subtitleListVisible,
    bool? subtitleListButtonVisible,
    Duration? position,
    Duration? duration,
    String? title,
    List<Subtitle>? subtitleList,
  }) {
    final partObj = super.copyWith(
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
    return CommPlayerDataState(
      aspectRatio: partObj.aspectRatio,
      subtitleListButtonVisible: partObj.subtitleListButtonVisible,
      subtitleList: partObj.subtitleList,
      subtitleListVisible: partObj.subtitleListVisible,
      player: partObj.player,
      loopIndex: partObj.loopIndex,
      playing: partObj.playing,
      subtitleState: partObj.subtitleState,
      position: partObj.position,
      duration: partObj.duration,
      volume: partObj.volume,
      speed: partObj.speed,
      mediaType: partObj.mediaType,
      title: partObj.title,
    );
  }

  @override
  CommPlayerDataState create({
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
  }) {
    return CommPlayerDataState(
      aspectRatio: aspectRatio,
      subtitleListButtonVisible: subtitleListButtonVisible,
      subtitleList: subtitleList,
      subtitleListVisible: subtitleListVisible,
      player: player,
      loopIndex: loopIndex,
      playing: playing,
      subtitleState: subtitleState,
      position: position,
      duration: duration,
      volume: volume,
      speed: speed,
      mediaType: mediaType,
      title: title,
    );
  }
}
