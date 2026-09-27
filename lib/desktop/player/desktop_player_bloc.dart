import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:mockingbird/desktop/player/desktop_player_event.dart';
import 'package:mockingbird/desktop/player/desktop_player_state.dart';
import 'package:mockingbird/desktop/player/ui/desktop_player_video_ui.dart';
import 'package:mockingbird/tool/comm_player/comm_player_bloc.dart';
import 'package:mockingbird/tool/comm_player/comm_player_state.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';

import '../../tool/extensions.dart';

class DesktopPlayerBloc extends CommPlayerBloc {
  static final shared = DesktopPlayerBloc._();

  DesktopPlayerBloc._() : super() {
    on<DesktopPlayerInitEvent>(_onInit);
    on<DesktopPlayerSelectMediaFromFileExplorerEvent>(
      _onSelectMediaFromFileExplorer,
    );
  }

  void _onInit(
    DesktopPlayerInitEvent event,
    Emitter<CommPlayerState> emit,
  ) async {
    await _setWindowForEmpty();
    emit(const CommPlayerEmptyState());
  }

  Future<void> _setWindowForEmpty() async {
    const minimumSize = Size(
      kDesktopPlayerLeftWidth,
      kDesktopPlayerEmptyHeight,
    );
    await windowManager.setTitle('Mockingbird');
    await windowManager.setSize(minimumSize);
    await windowManager.setMinimumSize(minimumSize);
    await windowManager.center();
  }

  void _onSelectMediaFromFileExplorer(
    DesktopPlayerSelectMediaFromFileExplorerEvent event,
    Emitter<CommPlayerState> emit,
  ) async {
    final xfile = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: [...kVideoExtensions, ...kAudioExtensions],
    );
    final filePath = xfile?.path;
    if (filePath == null) {
      return;
    }
    EasyLoading.show(maskType: .clear);
    final mediaFile = File(filePath);
    final prevState = state;
    final commState = await reload((
      loopIndex: null,
      mediaFile: mediaFile,
      mediaType: mediaFile.type,
      playing: true,
      position: Duration.zero,
      speed: 1,
      volume: 1,
      title: p.basename(mediaFile.path),
      subtitle: null,
    ));
    if (commState case CommPlayerDataState commData) {
      //TODO read db to get window frame, size
      final splitter = MultiSplitViewController();
      splitter.addArea(
        Area(
          // flex: 2,
          size: kDesktopPlayerLeftWidth,
          min: kDesktopPlayerLeftWidth,
          builder: (context, area) => const DesktopPlayerVideoLeftUI(),
        ),
      );
      splitter.addArea(
        Area(
          // flex: 1,
          size: kDesktopPlayerRightWidth,
          min: kDesktopPlayerRightWidth,
          builder: (context, area) => const DesktopPlayerVideoRightUI(),
        ),
      );
      if (prevState is CommPlayerEmptyState) {
        //transform from empty to data, should setup window size
        const minimumSize = Size(
          kDesktopPlayerLeftWidth +
              kDesktopPlayerRightWidth +
              kDesktopPlayerDividerThickness,
          kDesktopPlayerDataHeight,
        );
        await windowManager.setSize(minimumSize);
        await windowManager.setMinimumSize(minimumSize);
      }
      await windowManager.setTitle('Mockingbird - ${commData.title}');
      emit(
        DesktopPlayerDataState.commData(splitter: splitter, commData: commData),
      );
    } else {
      await _setWindowForEmpty();
      emit(commState);
    }
    EasyLoading.dismiss();
  }

  @override
  Future<void> close() {
    state.as<DesktopPlayerDataState>()?.splitter.dispose();
    return super.close();
  }
}
