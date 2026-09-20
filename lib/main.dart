import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:mockingbird/mobile/app/mobile_app_lifecycler.dart';
import 'package:mockingbird/mobile/app/mobile_app_ui.dart';
import 'package:mockingbird/mobile/tab_player/player/mobile_background_audio_player.dart';
import 'package:mockingbird/tool/extensions.dart';
import 'package:video_player_win/video_player_win.dart';
import 'package:window_manager/window_manager.dart';

import 'db/desktop_db.dart';
import 'db/mobile_db.dart';
import 'desktop/main_window/desktop_main_window_bloc.dart';
import 'desktop/main_window/desktop_main_window_ui.dart';

void main(List<String> argList) async {
  WidgetsFlutterBinding.ensureInitialized();
  switch (kPlatformType) {
    case .desktop:
      await _runDesktopApp(argList);
    default:
      await _runMobileApp();
  }
}

Future<void> _runDesktopApp(List<String> argList) async {
  i('argList: $argList');
  await DesktopDB.init();
  // Only the main window isolate initializes window_manager.
  await windowManager.ensureInitialized();
  WindowsVideoPlayer.registerWith();
  const minimumSize = Size(
    kDesktopPlayerMinWidth +
        kDesktopSubtitleMinWidth +
        kDesktopMainWindowDividerThickness,
    kDesktopMainWindowMinHeight,
  );
  const options = WindowOptions(
    size: minimumSize,
    minimumSize: minimumSize,
    center: true,
    title: 'Mockingbird',
  );
  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  // await window.setTitle('Mockingbird');
  // await window.setFrame(Offset.zero & const Size(600, 400));
  // await window.setMinimumSize(const Size(600, 400));
  // await window.center();
  runApp(const DesktopMainWindowUI());
}

Future<void> _runMobileApp() async {
  await MobileDB.init();
  await AudioService.init(
    builder: () => MobileBackgroundAudioPlayer(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.raypang.mockingbird.background_audio',
      androidNotificationChannelName: 'Mockingbird',
      androidStopForegroundOnPause: false,
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidShowNotificationBadge: true,
    ),
  );
  WidgetsBinding.instance.addObserver(MobileAppLifecycler());
  runApp(const MobileAppUI());
}
