import 'package:mockingbird/tool/comm_player/comm_player_state.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../db/entities/subtitle.dart';
import '../../mobile/tab_player/subtitle/subtitle_state.dart';

class DesktopPlayerDataState extends CommPlayerDataState {
  final MultiSplitViewController splitter;
  DesktopPlayerDataState.commData({
    required this.splitter,
    required CommPlayerDataState commData,
  }) : super(
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
    return DesktopPlayerDataState.commData(
      splitter: splitter,
      commData: commData,
    );
  }
}
