sealed class DesktopPlayerEvent {
  const DesktopPlayerEvent();
}

class DesktopPlayerPositionChangeByPlayingEvent extends DesktopPlayerEvent {
  final Duration position;
  const DesktopPlayerPositionChangeByPlayingEvent(this.position);
}

class DesktopPlayerSelectMediaFromFileExplorerEvent extends DesktopPlayerEvent {
  const DesktopPlayerSelectMediaFromFileExplorerEvent();
}

class DesktopPlayerResetSpeedEvent extends DesktopPlayerEvent {
  const DesktopPlayerResetSpeedEvent();
}

class DesktopPlayerIncSpeedEvent extends DesktopPlayerEvent {
  const DesktopPlayerIncSpeedEvent();
}

class DesktopPlayerDecSpeedEvent extends DesktopPlayerEvent {
  const DesktopPlayerDecSpeedEvent();
}

class DesktopPlayerShowSubtitleListEvent extends DesktopPlayerEvent {
  const DesktopPlayerShowSubtitleListEvent();
}

class DesktopPlayerHideSubtitleListEvent extends DesktopPlayerEvent {
  const DesktopPlayerHideSubtitleListEvent();
}

class DesktopPlayerToggleLoopEvent extends DesktopPlayerEvent {
  const DesktopPlayerToggleLoopEvent();
}

class DesktopPlayerPauseEvent extends DesktopPlayerEvent {
  const DesktopPlayerPauseEvent();
}

class DesktopPlayerPlayEvent extends DesktopPlayerEvent {
  const DesktopPlayerPlayEvent();
}

class DesktopPlayerToggleMuteEvent extends DesktopPlayerEvent {
  const DesktopPlayerToggleMuteEvent();
}

class DesktopPlayerMediaSliderStartChangeEvent extends DesktopPlayerEvent {
  final Duration position;
  final Duration duration;
  const DesktopPlayerMediaSliderStartChangeEvent(this.position, this.duration);
}

class DesktopPlayerMediaSliderChangingEvent extends DesktopPlayerEvent {
  final Duration position;
  final Duration duration;
  const DesktopPlayerMediaSliderChangingEvent(this.position, this.duration);
}

class DesktopPlayerMediaSliderEndChangeEvent extends DesktopPlayerEvent {
  final Duration position;
  final Duration duration;
  const DesktopPlayerMediaSliderEndChangeEvent(this.position, this.duration);
}

class DesktopPlayerVolumeChangeEvent extends DesktopPlayerEvent {
  final double volume;
  const DesktopPlayerVolumeChangeEvent(this.volume);
}
