import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:mockingbird/desktop/desktop_sub_window.dart';
import 'package:mockingbird/mobile/app/mobile_app_lifecycler.dart';
import 'package:mockingbird/mobile/app/mobile_app_ui.dart';
import 'package:mockingbird/mobile/tab_player/player/mobile_background_audio_player.dart';
import 'package:mockingbird/tool/extensions.dart';
import 'package:video_player_win/video_player_win.dart';
import 'package:window_manager/window_manager.dart';

import 'db/desktop_db.dart';
import 'db/mobile_db.dart';
import 'desktop/desktop_app_ui.dart';

void main(List<String> argList) async {
  WidgetsFlutterBinding.ensureInitialized(); //objectbox official code
  switch (kPlatformType) {
    case .desktop:
      await _runDesktopApp(argList);
    default:
      await _runMobileApp();
  }
}

Future<void> _runDesktopApp(List<String> argList) async {
  await DesktopDB.init();
  await windowManager.ensureInitialized();
  final windowController = await WindowController.fromCurrentEngine();
  await windowController.bindMethods();
  WindowsVideoPlayer.registerWith();

  // 判断是否通过 multi_window 启动
  if (argList.isNotEmpty && argList[0] == 'multi_window') {
    // 提取子窗口信息
    final windowId = argList[1];
    final Map<String, dynamic> argMap = argList.length > 2
        ? jsonDecode(argList[2])
        : {};
    final String typeRaw = argMap[kSubWindowTypeKey];
    final type = SubWindowType.raw(typeRaw);
    await _runSubWindow(windowId, type);
  } else {
    // 运行主窗口应用
    const options = WindowOptions(
      size: Size(600, 400),
      minimumSize: Size(600, 400),
      center: true,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    runApp(const DesktopAppUI());
  }
}

Future<void> _runSubWindow(String id, SubWindowType type) async {
  final WindowOptions options;
  switch (type) {
    case .subtitle:
      options = const WindowOptions(
        size: Size(600, 400),
        minimumSize: Size(400, 300),
        center: true,
      );
    case .about:
      options = const WindowOptions(
        size: Size(600, 400),
        minimumSize: Size(400, 300),
        center: true,
      );
  }
  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  // 运行子窗口应用
  final subWindow = DesktopSubWindow(id: id, type: type);
  runApp(subWindow);
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
