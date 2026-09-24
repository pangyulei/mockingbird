import 'package:flutter/widgets.dart';
import 'package:mockingbird/tool/comm_player/comm_player_event.dart';

class MobilePlayerToggleVolumeSliderEvent extends CommPlayerEvent {
  const MobilePlayerToggleVolumeSliderEvent();
}

class MobilePlayerInitEvent extends CommPlayerEvent {
  final String? mediaId;
  const MobilePlayerInitEvent(this.mediaId);
}

class MobilePlayerSyncFromBackgroundAudioEvent extends CommPlayerEvent {
  final Duration position;
  final bool playing;
  const MobilePlayerSyncFromBackgroundAudioEvent({
    required this.position,
    required this.playing,
  });
}

class MobilePlayerGoToAlbumListEvent extends CommPlayerEvent {
  final BuildContext context;
  const MobilePlayerGoToAlbumListEvent(this.context);
}
