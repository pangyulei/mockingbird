import 'dart:async';

import 'package:collection/collection.dart';
import 'package:defer/defer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:go_router/go_router.dart';
import 'package:mockingbird/mobile/app/mobile_app_route.dart';
import 'package:mockingbird/mobile/tab_player/player/mobile_player_event.dart';
import 'package:mockingbird/mobile/tab_player/player/mobile_player_state.dart';
import 'package:mockingbird/mobile/tab_player/player/mobile_player_ui.dart';
import 'package:mockingbird/mobile/tab_player/subtitle_list/mobile_subtitle_list_bloc.dart';
import 'package:mockingbird/mobile/tab_player/subtitle_list/mobile_subtitle_list_ui.dart';
import 'package:mockingbird/mobile/tab_player/sentence_card/sentence_card_bloc.dart';
import 'package:mockingbird/mobile/tab_player/sentence_card/sentence_card_event.dart';
import 'package:mockingbird/mobile/tab_player/sentence_card/sentence_card_ui.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:video_player/video_player.dart';

import '../../../db/entities/mobile_media_history.dart';
import '../../../db/entities/sentence.dart';
import '../../../db/entities/subtitle.dart';
import '../../../db/mobile_db.dart';
import '../../../tool/event_hub.dart';
import '../../../tool/extensions.dart';

const double _kMaxPlaySpeed = 3.0;
const double _kMinPlaySpeed = 0.2;
const double _kStepPlaySpeed = 0.1;

class SharedMobilePlayerBloc {
  static final instance = MobilePlayerBloc();
}


class MobilePlayerBloc extends PlayerBlocType {
  bool _mediaPlayingBeforeDrag = false;
  AssetEntity? _media;

  SpotType? get _spot {
    final state = this.state;
    if (state is! MobilePlayerDataState) return null;
    final sentenceList = state.selectedSubtitle?.sentenceList;
    final position = state.position;
    return sentenceList?.spot(position);
  }

  SpotType? _prevSpot;

  final _subscriptionList = <StreamSubscription>[];

  MobilePlayerBloc() : super(const MobilePlayerInitState()) {
    debugPrint('player bloc ${identityHashCode(this)} created');
    on<MobilePlayerInitEvent>(_onInit);
    on<MobilePlayerSelectAnotherSubtitleFromListEvent>(
      _onSelectAnotherSubtitleFromList,
    );
    on<MobilePlayerShowSubtitleListEvent>(_onShowSubtitleList);
    on<MobilePlayerHideSubtitleListEvent>(_onHideSubtitleList);
    on<MobilePlayerClickSentenceEvent>(_onClickSentence);
    on<MobilePlayerScrollToTopEvent>(_onScrollToTop);
    on<MobilePlayerScrollToBottomEvent>(_onScrollToBottom);
    on<MobilePlayerScrollToPlayingSentenceEvent>(_onScrollToPlayingSentence);
    on<MobilePlayerGoToAlbumListEvent>(_onGoToAlbumList);
    on<MobilePlayerPositionChangeByPlayingEvent>(_onPositionChangeByPlaying);
    on<MobilePlayerToggleVolumeEvent>(_onToggleVolume);
    on<MobilePlayerPauseEvent>(_onPause);
    on<MobilePlayerPlayEvent>(_onPlay);
    on<MobilePlayerToggleLoopEvent>(_onToggleLoop);
    on<MobilePlayerResetSpeedEvent>(_onResetSpeed);
    on<MobilePlayerIncSpeedEvent>(_onIncSpeed);
    on<MobilePlayerDecSpeedEvent>(_onDecSpeed);
    on<MobilePlayerMediaSliderStartChangeEvent>(_onMediaSliderStartChange);
    on<MobilePlayerMediaSliderChangingEvent>(_onMediaSliderChanging);
    on<MobilePlayerMediaSliderEndChangeEvent>(_onMediaSliderEndChange);
    on<MobilePlayerVolumeChangeEvent>(_onVolumeChange);
    on<MobilePlayerSyncFromBackgroundAudioEvent>(_onSyncFromBackgroundAudio);
    _subscriptionList.addAll([
      EventHub.on<HubSubtitleChangeEvent>(
        (event) =>
            add(MobilePlayerSelectAnotherSubtitleFromListEvent(event.name)),
      ),
      EventHub.on<HubAppPauseEvent>(_onAppPause),
      EventHub.on<HubSyncBackgroundAudioToPlayerEvent>(
        (event) => add(
          MobilePlayerSyncFromBackgroundAudioEvent(
            playing: event.playing,
            position: event.position,
          ),
        ),
      ),
    ]);
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
    var history = metadata.historyList.firstWhereOrNull(
      (h) => h.mediaId == _media?.id,
    );
    if (history != null) {
      history = history.copyWith(positionMs: position.inMilliseconds);
      await MobileDB.updateHistory(history);
    }
  }

  void _onSelectAnotherSubtitleFromList(
    MobilePlayerSelectAnotherSubtitleFromListEvent event,
    Emitter<MobilePlayerState> emit,
  ) async {
    var state = this.state;
    if (state is! MobilePlayerDataState) return;
    state = state.copyWith(
      subtitleListVisible: false,
      subtitleState: PlayerSubtitleDataState(
        subtitleName: event.name,
        sentenceList: state.selectedSubtitle?.sentenceList ?? [],
        initialAlignment: _spot?.alignment ?? 0,
        initialIndex: _spot?.index ?? 0,
      ),
    );
    emit(state);
    EventHub.emit(HubPlayingSentenceChangeEvent(_spot?.sentence.id));

    var metadata = await MobileDB.loadMetadata();
    var history = metadata.historyList.firstWhereOrNull(
      (h) => h.mediaId == _media?.id,
    );
    if (history != null) {
      history = history.copyWith(subtitleName: () => event.name);
      await MobileDB.updateHistory(history);
    }
  }

  void _onClickSentence(
    MobilePlayerClickSentenceEvent event,
    Emitter<MobilePlayerState> emit,
  ) async {
    /*Fix loop mode, tap sentence bug
    in loop mode, you seek from s(n)->s(n+1),
    because it beyond s(n) end, so it trigger reseek to start
    same reason you seek from s(n)->s(n-1) will works perfectly,
    so in loop mode, which sentence is loop wee need to manually maintain,
    can't rely on position listening
     */
    var dataState = state;
    if (dataState is! MobilePlayerDataState) return;
    final sentenceIndex = dataState.selectedSubtitle?.sentenceList
        .firstIndexWhereOrNull((sen) => sen.id == event.sentenceId);
    if (sentenceIndex == null) return;
    final sentence = dataState.selectedSubtitle?.sentenceList[sentenceIndex];
    if (sentence == null) return;
    if (dataState.loopIndex != null) {
      dataState = dataState.copyWith(loopIndex: () => sentenceIndex);
    }
    EventHub.emit(HubPlayingSentenceChangeEvent(sentence.id));
    final double alignment = sentenceIndex == 0 ? 0 : 0.3;
    dataState.scroller.safeScrollTo(sentenceIndex, alignment: alignment);
    emit(dataState.copyWith(playing: true));
    await dataState.player.seekTo(sentence.start);
    await dataState.player.play();
  }

  void _onShowSubtitleList(
    MobilePlayerShowSubtitleListEvent event,
    Emitter<MobilePlayerState> emit,
  ) {
    final state = this.state;
    if (state is! MobilePlayerDataState) return;
    emit(state.copyWith(subtitleListVisible: true));
  }

  void _onHideSubtitleList(
    MobilePlayerHideSubtitleListEvent event,
    Emitter<MobilePlayerState> emit,
  ) {
    final state = this.state;
    if (state is! MobilePlayerDataState) return;
    emit(state.copyWith(subtitleListVisible: false));
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

  void _onScrollToTop(
    MobilePlayerScrollToTopEvent event,
    Emitter<MobilePlayerState> emit,
  ) {
    state.as<MobilePlayerDataState>()?.scroller.safeScrollTo(0);
  }

  void _onScrollToBottom(
    MobilePlayerScrollToBottomEvent event,
    Emitter<MobilePlayerState> emit,
  ) {
    final dataState = state;
    if (dataState is! MobilePlayerDataState) return;
    final subtitle = dataState.selectedSubtitle;
    if (subtitle == null || subtitle.sentenceList.isEmpty) return;
    dataState.scroller.safeScrollTo(subtitle.sentenceList.length - 1);
  }

  void _onScrollToPlayingSentence(
    MobilePlayerScrollToPlayingSentenceEvent event,
    Emitter<MobilePlayerState> emit,
  ) {
    final index = _spot?.index;
    if (index == null) return;
    state.as<MobilePlayerDataState>()?.scroller.safeScrollTo(
      index,
      alignment: 0.3,
    );
  }

  void _onGoToAlbumList(
    MobilePlayerGoToAlbumListEvent event,
    Emitter<MobilePlayerState> emit,
  ) {
    event.context.go(MobileAppRoute.albumList);
  }

  void _onVolumeChange(
    MobilePlayerVolumeChangeEvent event,
    Emitter<MobilePlayerState> emit,
  ) async {
    var dataState = state;
    if (dataState is! MobilePlayerDataState) return;
    emit(dataState.copyWith(volume: event.volume));
    await dataState.player.setVolume(event.volume);
  }

  void _onPositionChangeByPlaying(
    MobilePlayerPositionChangeByPlayingEvent event,
    Emitter<MobilePlayerState> emit,
  ) async {
    //Fix switch media, old listener still execute bug
    if (_media == null) return;
    //Seperate dragging and playing position change listener

    var state = this.state;
    if (state is! MobilePlayerDataState) return;
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

  Future<void> _onPositionChangeByDragging(
    Duration position,
    Emitter<MobilePlayerState> emit,
  ) async {
    var state = this.state;
    if (state is! MobilePlayerDataState) return;
    if (state.playing) {
      state = state.copyWith(playing: false);
      emit(state);
      await state.player.pause();
    }
    await state.player.seekTo(position);
    final positionUpdated = _updatePropertiesWithPosition(
      position: position,
      emit: emit,
    );
    if (state.loopIndex != null) {
      state = state.copyWith(loopIndex: () => _spot?.index);
      emit(state);
    }
    if (positionUpdated.sentenceChanged) {
      //handle scroll
      final spot = _spot;
      if (spot != null) {
        state.scroller.safeJumpTo(spot.index, alignment: spot.alignment);
      }
    }
  }

  PositionUpdated _updatePropertiesWithPosition({
    required Duration position,
    required Emitter<MobilePlayerState> emit,
  }) {
    var result = (
      mediaCompleted: false,
      completedLoopSentence: null,
      sentenceChanged: false,
    );
    var state = this.state;
    if (state is! MobilePlayerDataState) return result;

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

  @override
  Future<void> close() {
    debugPrint('player bloc ${identityHashCode(this)} closed');
    for (final sub in _subscriptionList) {
      sub.cancel();
    }
    state.as<MobilePlayerDataState>()?.player.dispose();
    return super.close();
  }

  void _onToggleVolume(
    MobilePlayerToggleVolumeEvent event,
    Emitter<MobilePlayerState> emit,
  ) async {
    final state = this.state;
    if (state is! MobilePlayerDataState) return;
    emit(state.copyWith(volumeSliderVisible: !state.volumeSliderVisible));
  }

  void _onPlay(
    MobilePlayerPlayEvent event,
    Emitter<MobilePlayerState> emit,
  ) async {
    final state = this.state;
    if (state is! MobilePlayerDataState) return;
    emit(state.copyWith(playing: true));
    if (state.position >= state.duration) {
      await state.player.seekTo(Duration.zero);
    }
    await state.player.play();
  }

  void _onPause(
    MobilePlayerPauseEvent event,
    Emitter<MobilePlayerState> emit,
  ) async {
    final state = this.state;
    if (state is! MobilePlayerDataState) return;
    emit(state.copyWith(playing: false));
    await state.player.pause();
  }

  void _onToggleLoop(_, Emitter<MobilePlayerState> emit) {
    final state = this.state;
    if (state is! MobilePlayerDataState) return;
    if (state.loopIndex == null) {
      //to loop
      emit(state.copyWith(loopIndex: () => _spot?.index));
    } else {
      emit(state.copyWith(loopIndex: () => null));
    }
  }

  void _onMediaSliderStartChange(
    MobilePlayerMediaSliderStartChangeEvent event,
    Emitter<MobilePlayerState> emit,
  ) async {
    final state = this.state;
    if (state is! MobilePlayerDataState) return;
    _mediaPlayingBeforeDrag = state.playing;
    await _onPositionChangeByDragging(event.position, emit);
  }

  void _onMediaSliderChanging(
    MobilePlayerMediaSliderChangingEvent event,
    Emitter<MobilePlayerState> emit,
  ) async {
    await _onPositionChangeByDragging(event.position, emit);
  }

  void _onMediaSliderEndChange(
    MobilePlayerMediaSliderEndChangeEvent event,
    Emitter<MobilePlayerState> emit,
  ) async {
    var state = this.state;
    if (state is! MobilePlayerDataState) return;
    await _onPositionChangeByDragging(event.position, emit);
    if (event.position < event.duration && _mediaPlayingBeforeDrag) {
      emit(state.copyWith(playing: true));
      await state.player.play();
    }
  }

  void _onResetSpeed(
    MobilePlayerResetSpeedEvent event,
    Emitter<MobilePlayerState> emit,
  ) async {
    final state = this.state;
    if (state is! MobilePlayerDataState) return;
    final nextSpeed = (1.0).clamp(_kMinPlaySpeed, _kMaxPlaySpeed);
    emit(state.copyWith(speed: nextSpeed));
    await state.player.setPlaybackSpeed(nextSpeed);
  }

  void _onIncSpeed(
    MobilePlayerIncSpeedEvent event,
    Emitter<MobilePlayerState> emit,
  ) async {
    final state = this.state;
    if (state is! MobilePlayerDataState) return;
    final double nextSpeed = (state.speed + _kStepPlaySpeed)
        .clamp(_kMinPlaySpeed, _kMaxPlaySpeed)
        .digits(1);
    emit(state.copyWith(speed: nextSpeed));
    await state.player.setPlaybackSpeed(nextSpeed);
  }

  void _onDecSpeed(
    MobilePlayerDecSpeedEvent event,
    Emitter<MobilePlayerState> emit,
  ) async {
    final state = this.state;
    if (state is! MobilePlayerDataState) return;
    final double nextSpeed = (state.speed - _kStepPlaySpeed)
        .clamp(_kMinPlaySpeed, _kMaxPlaySpeed)
        .digits(1);
    emit(state.copyWith(speed: nextSpeed));
    await state.player.setPlaybackSpeed(nextSpeed);
  }

  void _onInit(
    MobilePlayerInitEvent event,
    Emitter<MobilePlayerState> emit,
  ) async {
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
      var history = metadata.historyList.firstWhereOrNull(
        (h) => h.mediaId == mediaId,
      );
      final position = history?.position ?? Duration.zero;
      state = await _reload((
        media: media,
        playing: true,
        position: position,
        loopIndex: null,
        selectedSubtitleName: history?.subtitleName,
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
            selectedSubtitleName: state.subtitleState.as<PlayerSubtitleDataState>()?.subtitleName,
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
        await MobileDB.updateMetadata(
          metadata.copyWith(playingMediaId: () => info?.media.id),
        );
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
        player.addListener(
          () => add(
            MobilePlayerPositionChangeByPlayingEvent(player.value.position),
          ),
        );
        final title = await info.media.titleAsync;
        var history = metadata.historyList.firstWhereOrNull(
          (h) => h.mediaId == info.media.id,
        );
        final (
          :subtitleList,
          :subtitleState,
          :subtitleListButtonVisible,
        ) = await _reloadSubtitle(
          info.media,
          info.selectedSubtitleName,
          info.position,
        );
        history =
            history?.copyWith(
              mediaId: info.media.id,
              positionMs: info.position.inMilliseconds,
              subtitleName: () => subtitleState.as<PlayerSubtitleDataState>()?.subtitleName,
            ) ??
            MobileMediaHistory(
              positionMs: info.position.inMilliseconds,
              mediaId: info.media.id,
              subtitleName: subtitleState.as<PlayerSubtitleDataState>()?.subtitleName,
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
              .firstWhereOrNull((s) => s.name == subtitleState.as<PlayerSubtitleDataState>()?.subtitleName)
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
          scroller: ItemScrollController(),
        );
      },
    );
    return newState;
  }

  Future<
    ({
      List<Subtitle> subtitleList,
      PlayerSubtitleState subtitleState,
      bool subtitleListButtonVisible,
    })
  >
  _reloadSubtitle(
    AssetEntity media,
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
    final PlayerSubtitleState subtitleState;
    if (spot == null || subtitle == null) {
      subtitleState = const PlayerSubtitleEmptyState();
    } else {
      subtitleState = PlayerSubtitleDataState(
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

  @override
  SentenceCardBlocType sentenceCardBlocAtIndex(int index) {
    final sentence = state
        .as<MobilePlayerDataState>()
        ?.selectedSubtitle
        ?.sentenceList[index];
    final playing = _spot?.index == index;
    return SentenceCardBloc(sentence)..add(SentenceCardInitEvent(playing));
  }

  @override
  MobileSubtitleListBlocType get subtitleListBlocType {
    return MobileSubtitleListBloc(
      state.as<MobilePlayerDataState>()?.subtitleList ?? [],
      state.as<MobilePlayerDataState>()?.subtitleState.as<PlayerSubtitleDataState>()?.subtitleName,
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
  //       debugPrint('Error adding subtitle: $e');
  //       return null;
  //     }
  //   }
  // }
}
