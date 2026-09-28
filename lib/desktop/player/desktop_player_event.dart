import 'dart:io';

import 'package:mockingbird/tool/comm_player/comm_player_event.dart';

class DesktopPlayerInitEvent extends CommPlayerEvent {
  const DesktopPlayerInitEvent();
}

class DesktopPlayerSelectMediaFromFileExplorerEvent extends CommPlayerEvent {
  const DesktopPlayerSelectMediaFromFileExplorerEvent();
}

class DesktopPlayerPickSubtitleFromFileExplorerEvent extends CommPlayerEvent {
  const DesktopPlayerPickSubtitleFromFileExplorerEvent();
}

class DesktopPlayerDropSubtitleEvent extends CommPlayerEvent {
  final File file;
  const DesktopPlayerDropSubtitleEvent(this.file);
}
