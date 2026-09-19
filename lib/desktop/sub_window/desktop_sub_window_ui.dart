import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:mockingbird/desktop/subtitle/desktop_subtitle_ui.dart';
import 'package:mockingbird/mobile/tab_settings/about/about_ui.dart';
import 'package:mockingbird/tool/extensions.dart';

const kSubWindowTypeKey = 'type';


class DesktopSubWindowUI extends StatelessWidget {
  final DesktopSubWindowType _type;
  final String _title;
  final String _id;
  const DesktopSubWindowUI({
    required this._type,
    required this._id,
    required this._title,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: Text(_title),
          actions: [
            // 子窗口主动关闭自身的按钮
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () async {
                final windowController = WindowController.fromWindowId(_id);
                await windowController.close();
              },
            ),
          ],
        ),
        body: _buildWindowBody(),
      ),
    );
  }

  Widget _buildWindowBody() {
    return switch (_type) {
      .subtitle => const DesktopSubtitleUI(),
      .about => const AboutUI()
    };
  }
}

enum DesktopSubWindowType {
  subtitle('subtitle'),
  about('about');

  final String raw;
  const DesktopSubWindowType(this.raw);
  factory DesktopSubWindowType.raw(String raw) {
    final type = DesktopSubWindowType.values.firstWhere((e) => e.raw == raw);
    return type;
  }
}
