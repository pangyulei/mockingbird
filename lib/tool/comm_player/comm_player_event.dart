import 'package:mockingbird/db/entities/subtitle.dart';

abstract class CommPlayerEvent {
  const CommPlayerEvent();
}

class CommPlayerInitEvent extends CommPlayerEvent {
  const CommPlayerInitEvent();
}

class CommPlayerClickSentenceEvent extends CommPlayerEvent {
  final String sentenceId;
  const CommPlayerClickSentenceEvent(this.sentenceId);
}

class CommPlayerShowSubtitleListEvent extends CommPlayerEvent {
  const CommPlayerShowSubtitleListEvent();
}

class CommPlayerHideSubtitleListEvent extends CommPlayerEvent {
  const CommPlayerHideSubtitleListEvent();
}

class CommPlayerSelectAnotherSubtitleFromListEvent extends CommPlayerEvent {
  final Subtitle subtitle;
  const CommPlayerSelectAnotherSubtitleFromListEvent(this.subtitle);
}

class CommPlayerScrollToTopEvent extends CommPlayerEvent {
  const CommPlayerScrollToTopEvent();
}

class CommPlayerScrollToBottomEvent extends CommPlayerEvent {
  const CommPlayerScrollToBottomEvent();
}

class CommPlayerScrollToPlayingSentenceEvent extends CommPlayerEvent {
  const CommPlayerScrollToPlayingSentenceEvent();
}

class CommPlayerVolumeChangeEvent extends CommPlayerEvent {
  final double volume;
  const CommPlayerVolumeChangeEvent(this.volume);
}

class CommPlayerPositionChangeByPlayingEvent extends CommPlayerEvent {
  final Duration position;
  const CommPlayerPositionChangeByPlayingEvent(this.position);
}

class CommPlayerPauseEvent extends CommPlayerEvent {
  const CommPlayerPauseEvent();
}

class CommPlayerPlayEvent extends CommPlayerEvent {
  const CommPlayerPlayEvent();
}

class CommPlayerToggleLoopEvent extends CommPlayerEvent {
  const CommPlayerToggleLoopEvent();
}

class CommPlayerDecSpeedEvent extends CommPlayerEvent {
  const CommPlayerDecSpeedEvent();
}

class CommPlayerIncSpeedEvent extends CommPlayerEvent {
  const CommPlayerIncSpeedEvent();
}

class CommPlayerResetSpeedEvent extends CommPlayerEvent {
  const CommPlayerResetSpeedEvent();
}

class CommPlayerMediaSliderStartChangeEvent extends CommPlayerEvent {
  final Duration position;
  final Duration duration;
  const CommPlayerMediaSliderStartChangeEvent(this.position, this.duration);
}

class CommPlayerMediaSliderChangingEvent extends CommPlayerEvent {
  final Duration position;
  final Duration duration;
  const CommPlayerMediaSliderChangingEvent(this.position, this.duration);
}

class CommPlayerMediaSliderEndChangeEvent extends CommPlayerEvent {
  final Duration position;
  final Duration duration;
  const CommPlayerMediaSliderEndChangeEvent(this.position, this.duration);
}
