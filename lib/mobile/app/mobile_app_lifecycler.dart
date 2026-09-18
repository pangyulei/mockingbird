import 'package:flutter/material.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../tool/event_hub.dart';

class MobileAppLifecycler with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    i('app state: $state');
    //退后台/锁屏 inactive->hidden->pause |后台中| ->hidden->inactive->resumed
    if (state == .resumed) {
      EventHub.emit(const HubAppResumeEvent());
    } else if (state == .paused) {
      EventHub.emit(const HubAppPauseEvent());
    }
  }
}
