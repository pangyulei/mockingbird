import 'package:photo_manager/photo_manager.dart';

import '../../../db/entities/subtitle.dart';
import '../../../tool/comm_player/comm_player_state.dart';
import '../subtitle/subtitle_state.dart';

class MobilePlayerDataState extends CommPlayerDataState {
  final bool volumeSliderVisible;

  MobilePlayerDataState.commData({required this.volumeSliderVisible, required CommPlayerDataState commData})
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
  MobilePlayerDataState copyWith({
    bool? volumeSliderVisible,
    int? Function()? loopIndex,
    bool? playing,
    double? aspectRatio,
    double? volume,
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
    return MobilePlayerDataState.commData(
      volumeSliderVisible: volumeSliderVisible ?? this.volumeSliderVisible,
      commData: commData,
    );
  }
}
