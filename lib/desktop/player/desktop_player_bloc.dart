import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:mockingbird/desktop/player/desktop_player_event.dart';
import 'package:mockingbird/tool/comm_player/comm_player_bloc.dart';
import 'package:mockingbird/tool/comm_player/comm_player_state.dart';

import '../../tool/extensions.dart';

//TODO use same bloc to handle player logic
class DesktopPlayerBloc extends CommPlayerBloc {
  static final shared = DesktopPlayerBloc._();

  DesktopPlayerBloc._() : super() {
    on<DesktopPlayerSelectMediaFromFileExplorerEvent>(_onSelectMediaFromFileExplorer);
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
    if (filePath == null) return;

    EasyLoading.show(maskType: .clear);
    final mediaFile = File(filePath);
    final state = await reload(mediaFile);
    emit(state);
    EasyLoading.dismiss();
  }
}
