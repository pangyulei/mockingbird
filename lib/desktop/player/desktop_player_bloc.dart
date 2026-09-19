
import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:defer/defer.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:mockingbird/db/entities/desktop_media_history.dart';
import 'package:mockingbird/db/entities/sentence.dart';
import 'package:mockingbird/desktop/player/desktop_player_event.dart';
import 'package:mockingbird/desktop/player/desktop_player_state.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as p;
import '../../db/desktop_db.dart';
import '../../db/entities/subtitle.dart';
import '../../mobile/tab_player/player/mobile_player_state.dart';
import '../../mobile/tab_player/sentence_card/sentence_card_bloc.dart';
import '../../mobile/tab_player/sentence_card/sentence_card_event.dart';
import '../../mobile/tab_player/sentence_card/sentence_card_ui.dart';
import '../../tool/event_hub.dart';
import '../../tool/extensions.dart';
import '../sub_window/desktop_sub_window_ui.dart';

class SharedDesktopPlayerBloc {
  static final instance = DesktopPlayerBloc();
}

class DesktopPlayerBloc extends Bloc<DesktopPlayerEvent, DesktopPlayerState> {
  File? _media;
  SpotType? get _spot {
    final state = this.state;
    if (state is! DesktopPlayerDataState) return null;
    final sentenceList = state.selectedSubtitle?.sentenceList;
    final position = state.position;
    return sentenceList?.spot(position);
  }
  SpotType? _prevSpot;

  DesktopPlayerBloc() : super(const DesktopPlayerEmptyState()) {
    on<DesktopPlayerSelectMediaFromFileExplorerEvent>(_selectMediaFromFileExplorer);
    on<DesktopPlayerPositionChangeByPlayingEvent>(_onPositionChangeByPlaying);
    on<DesktopPlayerShowSubtitleListEvent>(_onShowSubtitleList);
    on<DesktopPlayerHideSubtitleListEvent>(_onHideSubtitleList);
    on<DesktopPlayerSelectSubtitleEvent>(_onSelectSubtitle);
  }

  void _onSelectSubtitle(
      DesktopPlayerSelectSubtitleEvent event,
      Emitter<DesktopPlayerState> emit,
      ) async {
    var state = this.state;
    if (state is! DesktopPlayerDataState || _media == null) return;
    final (:subtitleList, :subtitleState, :subtitleListButtonVisible) = await _reloadSubtitle(_media!, event.name, state.position);
    emit(state.copyWith(
      subtitleList: subtitleList,
      subtitleState: subtitleState,
      subtitleListButtonVisible: subtitleListButtonVisible
    ));
    EventHub.emit(HubPlayingSentenceChangeEvent(_spot?.sentence.id));

    var metadata = await DesktopDB.loadMetadata();
    final index = metadata.historyList.indexWhere((h) => h.mediaPath == _media!.path);
    if (index != -1) {
      metadata.historyList[index] = metadata.historyList[index].copyWith(subtitleName: () => event.name);
      await DesktopDB.updateMetadata(metadata);
    }
  }

  void _onHideSubtitleList(
      DesktopPlayerHideSubtitleListEvent event,
      Emitter<DesktopPlayerState> emit,
      ) {
    final state = this.state;
    if (state is! DesktopPlayerDataState) return;
    emit(state.copyWith(subtitleListVisible: false));
  }

  void _onShowSubtitleList(
      DesktopPlayerShowSubtitleListEvent event,
      Emitter<DesktopPlayerState> emit,
      ) {
    final state = this.state;
    if (state is! DesktopPlayerDataState) return;
    emit(state.copyWith(subtitleListVisible: true));
  }


  void _onPositionChangeByPlaying(
      DesktopPlayerPositionChangeByPlayingEvent event,
      Emitter<DesktopPlayerState> emit,
      ) async {
    //Fix switch media, old listener still execute bug
    if (_media == null) return;
    //Seperate dragging and playing position change listener

    var state = this.state;
    if (state is! DesktopPlayerDataState) return;
    if (!state.playing) return;
    final positionUpdated = _updatePropertiesWithPosition(
      position: event.position,
      emit: emit,
    );
    if (positionUpdated.mediaCompleted) {
      //audo re-play media
      state = state.copyWith(playing: true);
      emit(state);
      await state.player.seekTo(Duration.zero);
      await state.player.play();
    }
    final completedLoopSentence = positionUpdated.completedLoopSentence;
    if (completedLoopSentence != null) {
      //reseek loop sentence
      await state.player.seekTo(completedLoopSentence.start);
    }
    if (positionUpdated.sentenceChanged) {
      //handle scroll
      if (state.loopIndex == null) {
        //playing auto scroll to next sentence, not for loop mode
        state.scroller.safeScrollTo(
          _spot?.index,
          alignment: _spot?.alignment ?? 0,
        );
      }
    }
  }


  PositionUpdated _updatePropertiesWithPosition({
    required Duration position,
    required Emitter<DesktopPlayerState> emit,
  }) {
    var result = (
    mediaCompleted: false,
    completedLoopSentence: null,
    sentenceChanged: false,
    );
    var state = this.state;
    if (state is! DesktopPlayerDataState) return result;

    //Fix while tap video slider, it bounce at first
    state = state.copyWith(position: position);
    emit(state);

    final mediaCompleted = position >= state.duration;

    //handle loop reseek
    final loopIndex = state.loopIndex;
    final loopSentence = loopIndex == null
        ? null
        : state.selectedSubtitle?.sentenceList.elementAtOrNull(loopIndex);
    SentenceEntity? completedLoopSentence;
    if (loopSentence != null && position > loopSentence.end) {
      //if repeat one is turn on, while sentence finished, seek to beginning
      completedLoopSentence = loopSentence;
    }

    //handle scroll
    final sentenceChanged = _spot?.sentence.id != _prevSpot?.sentence.id;
    if (sentenceChanged) {
      EventHub.emit(HubPlayingSentenceChangeEvent(_spot?.sentence.id));
    }
    _prevSpot = _spot;
    return (
    mediaCompleted: mediaCompleted,
    completedLoopSentence: completedLoopSentence,
    sentenceChanged: sentenceChanged,
    );
  }


  void _selectMediaFromFileExplorer(DesktopPlayerSelectMediaFromFileExplorerEvent event, Emitter<DesktopPlayerState> emit) async {
    final xfile = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: [
        ...kVideoExtensions,
        ...kAudioExtensions
      ],
    );
    final filePath = xfile?.path;
    if (filePath == null) return;

    EasyLoading.show(maskType: .clear);
    final mediaFile = File(filePath);
    final state = await _reload(mediaFile);
    emit(state);
    EasyLoading.dismiss();
    await _setupSubtitleWindow(state);
  }
  
  Future<void> _setupSubtitleWindow(DesktopPlayerState state) async {
    var subtitleWindow = (await WindowController.getAll()).firstWhereOrNull( (w) {
      return w.arguments.json['type'] == DesktopSubWindowType.subtitle.raw;
    });
    final subtitleName = state.as<DesktopPlayerDataState>()?.subtitleState.as<SubtitleDataState>()?.subtitleName;
    if (subtitleName == null) {
      //close subttile window
      await subtitleWindow?.close();

    } else {
      //open subtitle window
      if (subtitleWindow == null) {
        final arguments = {
          'type':DesktopSubWindowType.subtitle.raw,
          'title':subtitleName,
        }.string;
        subtitleWindow = await WindowController.create(WindowConfiguration(arguments: arguments));
        await subtitleWindow.show();
      }
      // await subtitleWindow.setTitle(subtitleName);
    }
  }

  Future<DesktopPlayerState> _reload(File? media) async {
    var metadata = await DesktopDB.loadMetadata();
    final newState = await defer<DesktopPlayerState>(
          () async {
        await DesktopDB.updateMetadata(
          metadata.copyWith(playingMediaPath: () => media?.path),
        );
        _media = media;
      },
          () async {
        //Fix switch media, old listener still execute bug
        _media = null;
        //Fix media deleted but still can here voice
        state.as<DesktopPlayerDataState>()?.player.dispose();
        if (media == null) {
          return const DesktopPlayerEmptyState();
        }
        final player = VideoPlayerController.file(media);
        await player.initialize();
        player.addListener(
              () => add(
            DesktopPlayerPositionChangeByPlayingEvent(player.value.position),
          ),
        );
        final title = p.basenameWithoutExtension(media.path);
        var history = metadata.historyList.firstWhereOrNull(
              (h) => h.mediaPath == media.path,
        );
        final position = history?.position ?? Duration.zero;
        final (
            :subtitleList,
            :subtitleState,
            :subtitleListButtonVisible,
        ) = await _reloadSubtitle(
          media,
          history?.subtitleName,
          position,
        );
        history =
            history?.copyWith(
              mediaPath: media.path,
              positionMs: position.inMilliseconds,
              subtitleName: () => subtitleState.as<SubtitleDataState>()?.subtitleName,
            ) ??
                DesktopMediaHistory(
                    mediaPath: media.path,
                    positionMs: position.inMilliseconds,
                    subtitleName: subtitleState.as<SubtitleDataState>()?.subtitleName,
                );
        if (history.id == 0) {
          metadata.historyList.add(history);
        }
        await player.seekTo(position);
        await player.play();
        final int? loopIndex;
        if (state.as<MobilePlayerDataState>()?.loopIndex == null) {
          loopIndex = null;
        } else {
          final sentenceList = subtitleList
              .firstWhereOrNull((s) => s.name == subtitleState.as<SubtitleDataState>()?.subtitleName)
              ?.sentenceList;
          loopIndex = sentenceList?.spot(position)?.index;
        }
        final mediaExtension = p.extension(media.path).substring(1);
        return DesktopPlayerDataState(
          aspectRatio: player.value.aspectRatio,
          subtitleList: subtitleList,
          subtitleListVisible: false,
          subtitleListButtonVisible: subtitleListButtonVisible,
          loopIndex: loopIndex,
          playing: true,
          subtitleState: subtitleState,
          position: position,
          duration: player.value.duration,
          volume: 1,
          speed: 1,
          mediaType: kAudioExtensions.contains(mediaExtension) ? .audio : .video,
          title: title,
          player: player,
          scroller: ItemScrollController(),
        );
      },
    );
    return newState;
  }

  Future<
      ({
      List<Subtitle> subtitleList,
      SubtitleState subtitleState,
      bool subtitleListButtonVisible,
      })
  >
  _reloadSubtitle(
      File media,
      String? selectedSubtitleName,
      Duration position,
      ) async {
    final subtitleList = await media.subtitleList;
    if (!subtitleList.any((s) => s.name == selectedSubtitleName)) {
      selectedSubtitleName = subtitleList.firstOrNull?.name;
    }
    final subtitle = subtitleList.firstWhereOrNull(
          (s) => s.name == selectedSubtitleName,
    );
    final spot = subtitle?.sentenceList.spot(position);
    EventHub.emit(HubPlayingSentenceChangeEvent(spot?.sentence.id));
    final SubtitleState subtitleState;
    if (spot == null || subtitle == null) {
      subtitleState = const SubtitleEmptyState();
    } else {
      subtitleState = SubtitleDataState(
        subtitleName: subtitle.name,
        sentenceList: subtitle.sentenceList,
        initialAlignment: spot.alignment,
        initialIndex: spot.index,
      );
    }
    return (
    subtitleList: subtitleList,
    subtitleState: subtitleState,
    subtitleListButtonVisible: subtitleList.length > 1,
    );
  }

  SentenceCardBlocType sentenceCardBlocAtIndex(int index) {
    final sentence = state.as<DesktopPlayerDataState>()?.selectedSubtitle?.sentenceList[index];
    final playing = _spot?.index == index;
    return SentenceCardBloc(sentence)..add(SentenceCardInitEvent(playing));
  }

  // Future<void> _handleFileSelection(
  //   BuildContext context,
  //   String filePath,
  // ) async {
  //   try {
  //     EasyLoading.show(status: 'Loading media file...');
  //     final fileName = filePath.split(Platform.pathSeparator).last;

  //     final assetPaths = await PhotoManager.getAssetPathList(
  //       type: RequestType.video | RequestType.audio,
  //     );

  //     AssetEntity? matchedAsset;
  //     for (final path in assetPaths) {
  //       final assetCount = await path.assetCountAsync;
  //       final assets = await path.getAssetListRange(start: 0, end: assetCount);
  //       for (final asset in assets) {
  //         final file = await asset.file;
  //         if (file?.path == filePath ||
  //             asset.title?.toLowerCase() == fileName.toLowerCase()) {
  //           matchedAsset = asset;
  //           break;
  //         }
  //       }
  //       if (matchedAsset != null) break;
  //     }

  //     if (matchedAsset == null) {
  //       final lowercasePath = filePath.toLowerCase();
  //       if (lowercasePath.endsWith('.mp4') ||
  //           lowercasePath.endsWith('.mov') ||
  //           lowercasePath.endsWith('.avi') ||
  //           lowercasePath.endsWith('.mkv')) {
  //         matchedAsset = await PhotoManager.editor.saveVideo(
  //           File(filePath),
  //           title: fileName,
  //         );
  //       } else {
  //         matchedAsset = await PhotoManager.editor.saveImageWithPath(
  //           filePath,
  //           title: fileName,
  //         );
  //       }
  //     }

  //     if (context.mounted) {
  //       context.read<DesktopPlayerBloc>().add(
  //         PlayerInitEvent(mediaId: matchedAsset.id),
  //       );
  //     }
  //   } catch (e) {
  //     i('Error handling file selection: $e');
  //     EasyLoading.showError('Failed to load file into player.');
  //   } finally {
  //     EasyLoading.dismiss();
  //   }
  // }
}
