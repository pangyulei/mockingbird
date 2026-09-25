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

    var metadata = await MobileDB.loadMetadata();
    var history = metadata.historyList.firstWhereOrNull((h) => h.mediaId == media?.id);
    if (history != null) {
      history = history.copyWith(subtitlePath: () => event.path);
      await MobileDB.updateHistory(history);
    }
  }

  void _onAppPause(HubAppPauseEvent event) async {
    if (state is! CommPlayerDataStateMx) return;
    if (media == null) return;

    //save position
    final data = state as CommPlayerDataStateMx;
    await _updateHistoryPosition(data.position);

    //sync to background audio player
    final playerInfo = PlayerInfo(
      media: media!,
      duration: data.duration,
      playing: data.playing,
      position: data.position,
      speed: data.speed,
      volume: data.volume,
      loopIndex: data.loopIndex,
      sentenceList: data.selectedSubtitle?.sentenceList ?? const [],
    );
    EventHub.emit(HubSyncPlayerToBackgroundAudioEvent(playerInfo));
  }

  Future<void> _updateHistoryPosition(Duration position) async {
    final metadata = await MobileDB.loadMetadata();
    var history = metadata.historyList.firstWhereOrNull((h) => h.mediaId == media?.id);
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

  void _onGoToAlbumList(MobilePlayerGoToAlbumListEvent event, Emitter<CommPlayerState> emit) {
    event.context.go(MobileAppRoute.albumList);
  }

  void _onToggleVolumeSlider(MobilePlayerToggleVolumeSliderEvent event, Emitter<CommPlayerState> emit) async {
    if (state is! MobilePlayerDataState) return;
    var data = state as MobilePlayerDataState;
    data = (data).copyWith(volumeSliderVisible: !data.volumeSliderVisible);
    emit(data);
  }

  void _onInit(MobilePlayerInitEvent event, Emitter<CommPlayerState> emit) async {
    EasyLoading.show(maskType: .clear);
    //before switch media, update old media's history position
    if (state is CommPlayerDataStateMx) {
      await _updateHistoryPosition((state as CommPlayerDataStateMx).position);
    }

    final metadata = await MobileDB.loadMetadata();
    final mediaId = event.mediaId ?? metadata.playingMediaId;
    final media = mediaId == null ? null : await AssetEntity.fromId(mediaId);
    CommPlayerState commState;
    if (media == null) {
      commState = await reload(null);
    } else {
      var history = metadata.historyList.firstWhereOrNull((h) => h.mediaId == mediaId);
      final position = history?.position ?? Duration.zero;
      commState = await reload((
        media: media,
        playing: true,
        position: position,
        loopIndex: null,
        subtitlePath: history?.subtitlePath,
        speed: 1,
        volume: 1,
      ));
    }
    if (commState is CommPlayerDataState) {
      commState = MobilePlayerDataState.commData(volumeSliderVisible: false, commData: commState);
    }
    emit(commState);
    EasyLoading.dismiss();
  }

  void _onSyncFromBackgroundAudio(MobilePlayerSyncFromBackgroundAudioEvent event, Emitter<CommPlayerState> emit) async {
    await defer(
      () async {
        EasyLoading.dismiss();
      },
      () async {
        EasyLoading.show(maskType: .clear);
        if (state is! CommPlayerDataStateMx) return;
        final mediaId = media?.id;
        if (mediaId == null) return;

        //refetch media because user might deleted media while leaving the app
        media = await AssetEntity.fromId(mediaId);
        final CommPlayerState newState;
        if (media == null) {
          newState = await reload(null);
        } else {
          final data = state as CommPlayerDataStateMx;
          newState = await reload((
            media: media!,
            selectedSubtitleName: data.selectedSubtitle?.name,
            loopIndex: data.loopIndex,
            position: event.position,
            playing: event.playing,
            volume: data.volume,
            speed: data.speed,
          ));
        }
        emit(state);
      },
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
