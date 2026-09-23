import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

import '../../db/entities/subtitle.dart';
import '../../mobile/tab_player/player/player_data_state.dart';
import '../../mobile/tab_player/subtitle/subtitle_state.dart';

sealed class DesktopPlayerState {
  const DesktopPlayerState();
}

class DesktopPlayerEmptyState extends DesktopPlayerState {
  const DesktopPlayerEmptyState();
}

abstract class DesktopPlayerDataStateBase extends DesktopPlayerState
    implements PlayerDataStateITF {
  const DesktopPlayerDataStateBase();
}

class DesktopPlayerDataState extends DesktopPlayerDataStateBase
    with PlayerDataStateImpl<DesktopPlayerDataState> {
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

  const DesktopPlayerDataState({
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
  DesktopPlayerDataState create({
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
    return DesktopPlayerDataState(
      loopIndex: loopIndex,
      playing: playing,
      title: title,
      position: position,
      duration: duration,
      volume: volume,
      speed: speed,
      aspectRatio: aspectRatio,
      mediaType: mediaType,
      subtitleListVisible: subtitleListVisible,
      subtitleList: subtitleList,
      subtitleState: subtitleState,
      player: player,
      subtitleListButtonVisible: subtitleListButtonVisible,
    );
  }

  DesktopPlayerDataState copyWith({
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
    return duplicate(
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
  }
}
