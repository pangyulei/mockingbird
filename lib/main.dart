
import 'package:audio_service/audio_service.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:mockingbird/desktop/sub_window/desktop_sub_window_ui.dart';
import 'package:mockingbird/mobile/app/mobile_app_lifecycler.dart';
import 'package:mockingbird/mobile/app/mobile_app_ui.dart';
import 'package:mockingbird/mobile/tab_player/player/mobile_background_audio_player.dart';
import 'package:mockingbird/tool/extensions.dart';
import 'package:video_player_win/video_player_win.dart';
import 'package:window_manager/window_manager.dart';

import 'db/desktop_db.dart';
import 'db/mobile_db.dart';
import 'desktop/desktop_main_window_ui.dart';

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
  final window = await WindowController.fromCurrentEngine();
  await window.bindMethods();
  if (argList.firstOrNull == 'multi_window') {
    i('sub window id: ${window.windowId}');
    i('sub window arguments: ${window.arguments}');
    // Sub-windows should NOT initialize window_manager as it crashes the secondary engines.
    // They should use their own WindowController for window management.
    final argumentMap = window.arguments.json;
    final title = argumentMap['title'];
    final type = DesktopSubWindowType.raw(argumentMap['type']);
    await _runDesktopSubWindow(window, title, type);
  } else {
    i('main window id: ${window.windowId}');
    i('main window arguments: ${window.arguments}');
    await DesktopDB.init();
    // Only the main window isolate initializes window_manager.
    await windowManager.ensureInitialized();
    WindowsVideoPlayer.registerWith();
    await _runDesktopMainWindow(window);
  }
}

Future<void> _runDesktopMainWindow(WindowController window) async {
  // 运行主窗口应用
  // const options = WindowOptions(
  //   size: Size(600, 400),
  //   minimumSize: Size(600, 400),
  //   center: true,
  // );
  // await windowManager.waitUntilReadyToShow(options, () async {
  //   await windowManager.show();
  //   await windowManager.focus();
  // });
  await window.setTitle('Mockingbird');
  await window.setFrame(Offset.zero & const Size(600, 400));
  await window.setMinimumSize(const Size(600, 400));
  await window.center();
  runApp(const DesktopMainWindowUI());
}

Future<void> _runDesktopSubWindow(WindowController window, String title, DesktopSubWindowType type) async {
  // Do NOT call window.setFrame or center() here using the controller instance in the sub-engine.
  // Those calls rely on the static channel being registered in the sub-engine, which crashes.
  // 运行子窗口应用
  // window..setFrame(Offset.zero & const Size(300, 400))..setMinimumSize(const Size(300, 400))..setTitle(title);
  runApp(DesktopSubWindowUI(id: window.windowId, title: title, type: type,));
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
