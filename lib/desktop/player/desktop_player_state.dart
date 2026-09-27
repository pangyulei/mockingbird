import 'package:mockingbird/tool/comm_player/comm_player_state.dart';
import 'package:multi_split_view/multi_split_view.dart';

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
         subtitleListButtonVisible: commData.subtitleListButtonVisible,
         subtitleListVisible: commData.subtitleListVisible,
         subtitleState: commData.subtitleState,
         title: commData.title,
         volume: commData.volume,
       );
}
