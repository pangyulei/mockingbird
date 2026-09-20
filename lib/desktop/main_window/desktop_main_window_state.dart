import 'package:multi_split_view/multi_split_view.dart';

sealed class DesktopMainWindowState {
  const DesktopMainWindowState();
}

class DesktopMainWindowInitState extends DesktopMainWindowState {
  const DesktopMainWindowInitState();
}

class DesktopMainWindowDataState extends DesktopMainWindowState {
  final MultiSplitViewController splitter;
  const DesktopMainWindowDataState({required this.splitter});
}
