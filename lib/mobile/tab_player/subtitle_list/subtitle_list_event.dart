import 'package:flutter/cupertino.dart';
import 'package:mockingbird/db/entities/subtitle.dart';

sealed class SubtitleListEvent {
  const SubtitleListEvent();
}

class SubtitleListInitEvent extends SubtitleListEvent {
  const SubtitleListInitEvent();
}

class SubtitleListSelectSubtitleEvent extends SubtitleListEvent {
  final Subtitle subtitle;
  final BuildContext context;
  const SubtitleListSelectSubtitleEvent(this.subtitle, this.context);
}
