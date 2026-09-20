import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockingbird/desktop/main_window/desktop_main_window_state.dart';
import 'package:mockingbird/desktop/player/desktop_player_ui.dart';
import 'package:mockingbird/desktop/subtitle/desktop_subtitle_ui.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:window_manager/window_manager.dart';

import 'desktop_main_window_event.dart';

const double kDesktopPlayerMinWidth = 600;
const double kDesktopSubtitleMinWidth = 300;
const double kDesktopMainWindowMinHeight = 500;
const double kDesktopMainWindowDividerThickness = 6; // 稍微加粗一点，方便鼠标抓取

class DesktopMainWindowBloc
    extends Bloc<DesktopMainWindowEvent, DesktopMainWindowState>
    with WindowListener {
  final _splitter = MultiSplitViewController();

  DesktopMainWindowBloc() : super(const DesktopMainWindowInitState()) {
    windowManager.addListener(this);
    on<DesktopMainWindowInitEvent>(_onInit);
  }

  FutureOr<void> _onInit(
    DesktopMainWindowInitEvent event,
    Emitter<DesktopMainWindowState> emit,
  ) {
    //TODO read db to get window frame, size
    _splitter.addArea(
      Area(
        // flex: 2,
        size: kDesktopPlayerMinWidth,
        min: kDesktopPlayerMinWidth,
        builder: (context, area) => const DesktopPlayerUI(),
      ),
    );
    _splitter.addArea(
      Area(
        // flex: 1,
        size: kDesktopSubtitleMinWidth,
        min: kDesktopSubtitleMinWidth,
        builder: (context, area) => const DesktopSubtitleUI(),
      ),
    );
    emit(DesktopMainWindowDataState(splitter: _splitter));
  }

  @override
  Future<void> close() {
    windowManager.removeListener(this);
    _splitter.dispose();
    return super.close();
  }
}
