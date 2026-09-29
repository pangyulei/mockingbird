import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:mockingbird/desktop/player/desktop_player_event.dart';
import 'package:mockingbird/desktop/player/desktop_player_state.dart';
import 'package:mockingbird/desktop/player/ui/desktop_player_video_ui.dart';
import 'package:mockingbird/tool/comm_player/comm_player_bloc.dart';
import 'package:mockingbird/tool/comm_player/comm_player_event.dart';
import 'package:mockingbird/tool/comm_player/comm_player_state.dart';
import 'package:mockingbird/tool/subtitle_parser.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';

import '../../tool/extensions.dart';

class DesktopPlayerBloc extends CommPlayerBloc {
  static final shared = DesktopPlayerBloc._();

  DesktopPlayerBloc._() : super() {
    on<DesktopPlayerInitEvent>(_onInit);
    on<DesktopPlayerPickMediaFromFileExplorerEvent>(
      _onPickMediaFromFileExplorer,
    );
    on<DesktopPlayerDropMediaEvent>(_onDropMedia);
    on<DesktopPlayerPickSubtitleFromFileExplorerEvent>(
      _onPickSubtitleFromFileExplorer,
    );
    on<DesktopPlayerDropSubtitleEvent>(_onDropSubtitle);
    on<DesktopPlayerToggleMuteEvent>(_onToggleMute);
  }

  void _onInit(
    DesktopPlayerInitEvent event,
    Emitter<CommPlayerState> emit,
  ) async {
    await _setWindowForEmpty(emit);
  }

  Future<void> _setWindowForEmpty(Emitter<CommPlayerState> emit) async {
    const minimumSize = Size(
      kDesktopPlayerLeftWidth,
      kDesktopPlayerEmptyHeight,
    );
    await windowManager.setTitle('Mockingbird');
    await windowManager.setMinimumSize(minimumSize);
    await windowManager.setSize(minimumSize);
    await windowManager.center();
    emit(const CommPlayerEmptyState());
  }

  void _onPickMediaFromFileExplorer(
    DesktopPlayerPickMediaFromFileExplorerEvent event,
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
    await _loadMediaFile(File(filePath), emit);
  }

  void _onDropMedia(
    DesktopPlayerDropMediaEvent event,
    Emitter<CommPlayerState> emit,
  ) async {
    final extension = p
        .extension(event.file.path)
        .replaceAll('.', '')
        .toLowerCase();
    if (!kVideoExtensions.contains(extension) &&
        !kAudioExtensions.contains(extension)) {
      EasyLoading.showError('Unsupported media format');
      return;
    }
    await _loadMediaFile(event.file, emit);
  }

  Future<void> _loadMediaFile(
    File mediaFile,
    Emitter<CommPlayerState> emit,
  ) async {
    EasyLoading.show(maskType: .clear);
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
      await windowManager.setTitle('Mockingbird - ${commData.title}');
      if (mediaFile.type == .video) {
        await _setWindowForVideoUI(commData, emit);
      } else {
        await _setWindowForAudioUI(commData, emit);
      }
    } else {
      await _setWindowForEmpty(emit);
    }
    EasyLoading.dismiss();
  }

  Future<void> _setWindowForAudioUI(
    CommPlayerDataState commData,
    Emitter<CommPlayerState> emit,
  ) async {
    if (state is CommPlayerEmptyState ||
        state.as<CommPlayerDataState>()?.mediaType == .video) {
      //transform from empty to data, should setup window size
      const minimumSize = Size(400, 700);
      await windowManager.setMinimumSize(minimumSize);
      await windowManager.setSize(minimumSize);
    }
    emit(DesktopPlayerDataState(commData: commData, muting: false));
  }

  Future<void> _setWindowForVideoUI(
    CommPlayerDataState commData,
    Emitter<CommPlayerState> emit,
  ) async {
    //TODO read db to get window frame, size
    final MultiSplitViewController? splitter;
    if (state is CommPlayerEmptyState ||
        state.as<CommPlayerDataState>()?.mediaType == .audio) {
      //transform from empty to data, should setup window size
      const minimumSize = Size(
        kDesktopPlayerLeftWidth +
            kDesktopPlayerRightWidth +
            kDesktopPlayerDividerThickness,
        kDesktopPlayerDataHeight,
      );
      await windowManager.setMinimumSize(minimumSize);
      await windowManager.setSize(minimumSize);

      splitter = MultiSplitViewController();
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
    } else {
      splitter = (state as DesktopPlayerVideoDataState).splitter;
    }
    emit(
      DesktopPlayerVideoDataState(
        splitter: splitter,
        data: DesktopPlayerDataState(commData: commData, muting: false),
      ),
    );
  }

  void _onPickSubtitleFromFileExplorer(
    DesktopPlayerPickSubtitleFromFileExplorerEvent event,
    Emitter<CommPlayerState> emit,
  ) async {
    if (state is! CommPlayerDataState) return;
    final xfile = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: [...kSubtitleExtensions],
    );
    final path = xfile?.path;
    if (path == null) return;
    await _loadSubtitleFile(File(path), emit);
  }

  void _onDropSubtitle(
    DesktopPlayerDropSubtitleEvent event,
    Emitter<CommPlayerState> emit,
  ) async {
    if (state is! CommPlayerDataState) return;
    await _loadSubtitleFile(event.file, emit);
  }

  Future<void> _loadSubtitleFile(
    File file,
    Emitter<CommPlayerState> emit,
  ) async {
    final extension = p.extension(file.path).replaceAll('.', '').toLowerCase();
    if (!kSubtitleExtensions.contains(extension)) {
      EasyLoading.showError('Invalid subtitle format. Supported: .srt, .vtt');
      return;
    }

    final subtitle = await SubtitleParser.parseFile(file);
    if (subtitle == null) {
      EasyLoading.showError('Failed to parse subtitle file');
      return;
    }

    var data = state as CommPlayerDataState;
    var argSubtitleList = data.subtitleList.contains(subtitle)
        ? data.subtitleList.map((s) => s == subtitle ? subtitle : s).toList()
        : [...data.subtitleList, subtitle];

    final (:subtitleList, :subtitleState) = await reloadSubtitle(
      argSubtitleList,
      subtitle,
      data.position,
    );

    emit(
      data.rCopyWith(subtitleList: subtitleList, subtitleState: subtitleState),
    );
    EasyLoading.showSuccess('Subtitle added successfully');
  }

  @override
  Future<void> close() {
    state.as<DesktopPlayerVideoDataState>()?.splitter.dispose();
    return super.close();
  }

  Future<void> _onToggleMute(
    DesktopPlayerToggleMuteEvent event,
    Emitter<CommPlayerState> emit,
  ) async {
    var data = state.as<DesktopPlayerDataState>();
    if (data == null) return;
    if (data.muting) {
      //re-assign volume back
      await data.player.setVolume(data.volume);
    } else {
      //silent
      await data.player.setVolume(0);
    }
    data = data.copyWith(muting: !data.muting);
    emit(data);
  }

  @override
  Future<void> onVolumeChange(
    CommPlayerVolumeChangeEvent event,
    Emitter<CommPlayerState> emit,
  ) async {
    await super.onVolumeChange(event, emit);
    if (state case DesktopPlayerDataState data) {
      emit(data.copyWith(muting: false));
    }
  }
}
