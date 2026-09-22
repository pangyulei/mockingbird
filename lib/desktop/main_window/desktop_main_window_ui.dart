import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../player/desktop_player_ui.dart';

class DesktopMainWindowUI extends StatefulWidget {
  const DesktopMainWindowUI({super.key});

  @override
  State<StatefulWidget> createState() => _DesktopMainWindowUIState();
}

class _DesktopMainWindowUIState extends State<DesktopMainWindowUI> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: EasyLoading.init(),
      home: const DesktopPlayerUI(),
    );
  }
}
