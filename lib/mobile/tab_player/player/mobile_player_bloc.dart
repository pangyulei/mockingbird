import 'dart:async';

import 'package:collection/collection.dart';
import 'package:defer/defer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:go_router/go_router.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:mockingbird/mobile/app/mobile_app_route.dart';
import 'package:mockingbird/mobile/tab_player/player/mobile_player_event.dart';
import 'package:mockingbird/mobile/tab_player/player/mobile_player_state.dart';
import 'package:mockingbird/mobile/tab_player/sentence_card/sentence_card_bloc.dart';
import 'package:mockingbird/mobile/tab_player/sentence_card/sentence_card_event.dart';
import 'package:mockingbird/mobile/tab_player/sentence_card/sentence_card_ui.dart';
import 'package:mockingbird/mobile/tab_player/subtitle_list/mobile_subtitle_list_bloc.dart';
import 'package:mockingbird/mobile/tab_player/subtitle_list/mobile_subtitle_list_ui.dart';
import 'package:mockingbird/tool/comm_player/comm_player_bloc.dart';
import 'package:mockingbird/tool/comm_player/comm_player_state.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:video_player/video_player.dart';

import '../../../db/entities/mobile_media_history.dart';
import '../../../db/entities/sentence.dart';
import '../../../db/entities/subtitle.dart';
import '../../../db/mobile_db.dart';
import '../../../tool/comm_player/comm_player_event.dart';
import '../../../tool/event_hub.dart';
import '../../../tool/extensions.dart';
import '../subtitle/subtitle_state.dart';

class MobilePlayerBloc extends Bloc<CommPlayerEvent, CommPlayerState> with CommPlayerBloc {
  static final shared = MobilePlayerBloc._();

  MobilePlayerBloc._() : super(const CommPlayerInitState()) {
    registerEvents();
    on<MobilePlayerInitEvent>(_onInit);
    on<MobilePlayerGoToAlbumListEvent>(_onGoToAlbumList);
    on<MobilePlayerSyncFromBackgroundAudioEvent>(_onSyncFromBackgroundAudio);
    on<MobilePlayerToggleVolumeSliderEvent>(_onToggleVolumeSlider);
    subscriptionList.addAll([
      EventHub.on<HubAppPauseEvent>(_onAppPause),
      EventHub.on<HubSyncBackgroundAudioToPlayerEvent>(
        (event) => add(MobilePlayerSyncFromBackgroundAudioEvent(playing: event.playing, position: event.position)),
      ),
    ]);
  }

  @override
  void onSelectAnotherSubtitleFromList(
    CommPlayerSelectAnotherSubtitleFromListEvent event,
    Emitter<CommPlayerState> emit,
  ) async {
    super.onSelectAnotherSubtitleFromList(event, emit);

      //TODO use mobile event to handle
      var metadata = await MobileDB.loadMetadata();
      var history = metadata.historyList.firstWhereOrNull((h) => h.mediaId == media?.id);
      if (history != null) {
        history = history.copyWith(subtitlePath: () => event.path);
        await MobileDB.updateHistory(history);
      }
    }
  }

  void _onAppPause(HubAppPauseEvent event) async {
    final state = this.state;
    if (state is! MobilePlayerDataState) return;
    final media = _media;
    if (media == null) return;

    //save position
    await _updateHistoryPosition(state.position);

    //sync to background audio player
    final playerInfo = PlayerInfo(
      media: media,
      duration: state.duration,
      playing: state.playing,
      position: state.position,
      speed: state.speed,
      volume: state.volume,
      loopIndex: state.loopIndex,
      sentenceList: state.selectedSubtitle?.sentenceList ?? const [],
    );
    EventHub.emit(HubSyncPlayerToBackgroundAudioEvent(playerInfo));
  }

  Future<void> _updateHistoryPosition(Duration position) async {
    final state = this.state;
    if (state is! MobilePlayerDataState) return;
    final metadata = await MobileDB.loadMetadata();
    var history = metadata.historyList.firstWhereOrNull((h) => h.mediaId == _media?.id);
    if (history != null) {
      history = history.copyWith(positionMs: position.inMilliseconds);
      await MobileDB.updateHistory(history);
    }
  }

  //TODO if no subtitle match, able to select subtitle
  // void _onPickLibraryFileForSubtitle() async {

  // }

  // void _onSelectSubtitle(
  //   PlayerSelectSubtitleEvent event,
  //   Emitter<PlayerState> emit,
  // ) async {
  //   final state = this.state;
  //   if (state is! PlayerDataState) return;
  //   final subtitle = state.subtitleList[event.index];
  //   if (_subtitle == subtitle) return;

  //   _prevSubtitle = null; // force reload scroller
  //   final subtitleState = PlayerSubtitleDataState(subtitle.sentenceList);

  //   // Save selection to metadata
  //   var metadata = await MobileDB.loadMetadata();
  //   metadata = metadata.copyWith(playingSubtitleName: () => subtitle.name);
  //   await MobileDB.updateMetadata(metadata);

  //   emit(
  //     state.copyWith(
  //       subtitleState: subtitleState,
  //       selectedSubtitleIndex: () => event.index,
  //       showSubtitleList: false, // Close list after selection
  //     ),
  //   );
  // }

  void _onGoToAlbumList(MobilePlayerGoToAlbumListEvent event, Emitter<MobilePlayerState> emit) {
    event.context.go(MobileAppRoute.albumList);
  }

  void _onToggleVolumeSlider(MobilePlayerToggleVolumeSliderEvent event, Emitter<MobilePlayerState> emit) async {
    final state = this.state;
    if (state is! MobilePlayerDataState) return;
    emit(state.copyWith(volumeSliderVisible: !state.volumeSliderVisible));
  }

  void _onInit(MobilePlayerInitEvent event, Emitter<MobilePlayerState> emit) async {
    EasyLoading.show(maskType: .clear);
    //before switch media, update old media's history position
    var state = this.state;
    if (state is MobilePlayerDataState) {
      await _updateHistoryPosition(state.position);
    }

    final metadata = await MobileDB.loadMetadata();
    final mediaId = event.mediaId ?? metadata.playingMediaId;
    final media = mediaId == null ? null : await AssetEntity.fromId(mediaId);
    if (media == null) {
      state = await _reload(null);
    } else {
      var history = metadata.historyList.firstWhereOrNull((h) => h.mediaId == mediaId);
      final position = history?.position ?? Duration.zero;
      state = await _reload((
        media: media,
        playing: true,
        position: position,
        loopIndex: null,
        selectedSubtitleName: history?.subtitlePath,
        speed: 1,
        volume: 1,
      ));
    }
    emit(state);
    EasyLoading.dismiss();
  }

  void _onSyncFromBackgroundAudio(
    MobilePlayerSyncFromBackgroundAudioEvent event,
    Emitter<MobilePlayerState> emit,
  ) async {
    await defer(
      () async {
        EasyLoading.dismiss();
      },
      () async {
        EasyLoading.show(maskType: .clear);
        var state = this.state;
        if (state is! MobilePlayerDataState) return;
        final mediaId = _media?.id;
        if (mediaId == null) return;

        final media = await AssetEntity.fromId(mediaId);
        if (media == null) {
          state = await _reload(null);
        } else {
          state = await _reload((
            media: media,
            selectedSubtitleName: state.subtitleState.as<SubtitleDataState>()?.subtitleName,
            loopIndex: state.loopIndex,
            position: event.position,
            playing: event.playing,
            volume: state.volume,
            speed: state.speed,
          ));
        }
        emit(state);
      },
    );
  }

  Future<MobilePlayerState> _reload(
    ({
      AssetEntity media,
      bool playing,
      int? loopIndex,
      Duration position,
      String? selectedSubtitleName,
      double volume,
      double speed,
    })?
    info,
  ) async {
    var metadata = await MobileDB.loadMetadata();
    final newState = await defer<MobilePlayerState>(
      () async {
        await MobileDB.updateMetadata(metadata.copyWith(playingMediaId: () => info?.media.id));
        _media = info?.media;
      },
      () async {
        //Fix switch media, old listener still execute bug
        _media = null;
        //Fix media deleted but still can here voice
        state.as<MobilePlayerDataState>()?.player.dispose();
        if (info == null) {
          return const MobilePlayerEmptyState();
        }
        //because of this is read and have to await, this has to be a AsyncNotifier
        final mediaFile = await info.media.file;
        if (mediaFile == null) {
          return const MobilePlayerEmptyState();
        }
        final player = VideoPlayerController.file(mediaFile);
        await player.initialize();
        player.addListener(() => add(MobilePlayerPositionChangeByPlayingEvent(player.value.position)));
        final title = await info.media.titleAsync;
        var history = metadata.historyList.firstWhereOrNull((h) => h.mediaId == info.media.id);
        final (:subtitleList, :subtitleState, :subtitleListButtonVisible) = await _reloadSubtitle(
          info.media,
          info.selectedSubtitleName,
          info.position,
        );
        history =
            history?.copyWith(
              mediaId: info.media.id,
              positionMs: info.position.inMilliseconds,
              subtitlePath: () => subtitleState.as<SubtitleDataState>()?.subtitleName,
            ) ??
            MobileMediaHistory(
              positionMs: info.position.inMilliseconds,
              mediaId: info.media.id,
              subtitlePath: subtitleState.as<SubtitleDataState>()?.subtitleName,
            );
        if (history.id == 0) {
          metadata.historyList.add(history);
        }
        await player.seekTo(info.position);
        if (info.playing) {
          await player.play();
        }
        final int? loopIndex;
        if (state.as<MobilePlayerDataState>()?.loopIndex == null) {
          loopIndex = null;
        } else {
          final sentenceList = subtitleList
              .firstWhereOrNull((s) => s.name == subtitleState.as<SubtitleDataState>()?.subtitleName)
              ?.sentenceList;
          loopIndex = sentenceList?.spot(info.position)?.index;
        }
        return MobilePlayerDataState(
          aspectRatio: player.value.aspectRatio,
          subtitleList: subtitleList,
          subtitleListVisible: false,
          subtitleListButtonVisible: subtitleListButtonVisible,
          volumeSliderVisible: false,
          loopIndex: loopIndex,
          playing: info.playing,
          subtitleState: subtitleState,
          position: info.position,
          duration: player.value.duration,
          volume: info.volume,
          speed: info.speed,
          mediaType: info.media.type,
          title: title,
          player: player,
        );
      },
    );
    return newState;
  }

  Future<({List<Subtitle> subtitleList, SubtitleState subtitleState, bool subtitleListButtonVisible})> _reloadSubtitle(
    AssetEntity media,
    String? selectedSubtitleName,
    Duration position,
  ) async {
    final subtitleList = await media.subtitleList;
    if (!subtitleList.any((s) => s.name == selectedSubtitleName)) {
      selectedSubtitleName = subtitleList.firstOrNull?.name;
    }
    final subtitle = subtitleList.firstWhereOrNull((s) => s.name == selectedSubtitleName);
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
        scroller: _scroller,
      );
    }
    return (
      subtitleList: subtitleList,
      subtitleState: subtitleState,
      subtitleListButtonVisible: subtitleList.length > 1,
    );
  }

  SentenceCardBlocType sentenceCardBlocAtIndex(int index) {
    final sentence = state.as<MobilePlayerDataState>()?.selectedSubtitle?.sentenceList[index];
    final playing = _spot?.index == index;
    return SentenceCardBloc(sentence)..add(SentenceCardInitEvent(playing));
  }

  MobileSubtitleListBlocType get subtitleListBlocType {
    return MobileSubtitleListBloc(
      state.as<MobilePlayerDataState>()?.subtitleList ?? [],
      state.as<MobilePlayerDataState>()?.subtitleState.as<SubtitleDataState>()?.subtitleName,
    );
  }

  //   Future<String?> _pickOneSubtitle() async {
  //     try {
  //       final subtitleExtensions = {'.srt', '.vtt'};
  //       final pickedFiles = await FilePicker.pickFiles(
  //         type: FileType.custom,
  //         allowedExtensions: [...subtitleExtensions],
  //       );
  //       final subtitlePath = pickedFiles
  //           .map((pf) => File(pf.xFile.path))
  //           .toList()
  //           .firstWhereOrNull(
  //             (f) => subtitleExtensions.contains(p.extension(f.path)),
  //           )
  //           ?.path;
  //       return subtitlePath;
  //     } catch (e) {
  //       i('Error adding subtitle: $e');
  //       return null;
  //     }
  //   }
  // }
}
