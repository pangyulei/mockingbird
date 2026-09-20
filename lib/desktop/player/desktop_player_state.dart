import 'package:collection/collection.dart';
import 'package:mockingbird/mobile/tab_player/player/mobile_player_state.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:video_player/video_player.dart';

import '../../db/entities/subtitle.dart';
import '../../mobile/tab_player/subtitle/subtitle_state.dart';

sealed class DesktopPlayerState {
  const DesktopPlayerState();
}

class DesktopPlayerEmptyState extends DesktopPlayerState {
  const DesktopPlayerEmptyState();
}

class DesktopPlayerDataState extends DesktopPlayerState {
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
    return DesktopPlayerDataState(
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

  Subtitle? get selectedSubtitle {
    final subtitleState = this.subtitleState;
    if (subtitleState is! SubtitleDataState) return null;
    return subtitleList.firstWhereOrNull((s) => s.name == subtitleState.subtitleName);
  }
}