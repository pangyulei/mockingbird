import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'player/ui/desktop_player_ui.dart';

class DesktopMainWindowUI extends StatelessWidget {
  const DesktopMainWindowUI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: EasyLoading.init(),
      home: const DesktopPlayerUI(),
    );
  }
}
