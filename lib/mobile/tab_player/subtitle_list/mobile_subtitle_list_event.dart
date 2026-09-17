import 'package:flutter/cupertino.dart';

sealed class MobileSubtitleListEvent {
  const MobileSubtitleListEvent();
}

class MobileSubtitleListInitEvent extends MobileSubtitleListEvent {
  const MobileSubtitleListInitEvent();
}

class MobileSubtitleListSelectNameEvent extends MobileSubtitleListEvent {
  final String name;
  final BuildContext context;
  const MobileSubtitleListSelectNameEvent(this.name, this.context);
}
