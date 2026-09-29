import 'package:mockingbird/tool/comm_player/comm_player_state.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../db/entities/subtitle.dart';
import '../../mobile/tab_player/subtitle/subtitle_state.dart';

class DesktopPlayerVideoDataState extends DesktopPlayerDataState {
  final MultiSplitViewController splitter;
  DesktopPlayerVideoDataState({required this.splitter, required DesktopPlayerDataState data})
    : super(commData: data, muting: data.muting);

  @override
  DesktopPlayerVideoDataState copyWith({
    int? Function()? loopIndex,
    bool? playing,
    double? aspectRatio,
    double? volume,
    bool? muting,
    double? speed,
    SubtitleState? subtitleState,
    AssetType? mediaType,
    bool? subtitleListVisible,
    Duration? position,
    Duration? duration,
    String? title,
    List<Subtitle>? subtitleList,
  }) {
    final data = super.copyWith(
      loopIndex: loopIndex,
      playing: playing,
      aspectRatio: aspectRatio,
      volume: volume,
      speed: speed,
      subtitleState: subtitleState,
      mediaType: mediaType,
      subtitleListVisible: subtitleListVisible,
      position: position,
      duration: duration,
      title: title,
      subtitleList: subtitleList,
      muting: muting,
    );
    return DesktopPlayerVideoDataState(data: data, splitter: splitter);
  }
}

class DesktopPlayerDataState extends CommPlayerDataState {
  final bool muting;
  DesktopPlayerDataState({required this.muting, required CommPlayerDataState commData})
    : super(
        aspectRatio: commData.aspectRatio,
        duration: commData.duration,
        loopIndex: commData.loopIndex,
        mediaType: commData.mediaType,
        player: commData.player,
        playing: commData.playing,
        position: commData.position,
        speed: commData.speed,
        subtitleList: commData.subtitleList,
        subtitleListVisible: commData.subtitleListVisible,
        subtitleState: commData.subtitleState,
        title: commData.title,
        volume: commData.volume,
      );

  @override
  DesktopPlayerDataState copyWith({
    int? Function()? loopIndex,
    bool? playing,
    double? aspectRatio,
    double? volume,
    bool? muting,
    double? speed,
    SubtitleState? subtitleState,
    AssetType? mediaType,
    bool? subtitleListVisible,
    Duration? position,
    Duration? duration,
    String? title,
    List<Subtitle>? subtitleList,
  }) {
    final commData = super.copyWith(
      loopIndex: loopIndex,
      playing: playing,
      aspectRatio: aspectRatio,
      volume: volume,
      speed: speed,
      subtitleState: subtitleState,
      mediaType: mediaType,
      subtitleListVisible: subtitleListVisible,
      position: position,
      duration: duration,
      title: title,
      subtitleList: subtitleList,
    );
    return DesktopPlayerDataState(commData: commData, muting: muting ?? this.muting);
  }
}
