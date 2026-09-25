import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:mockingbird/db/entities/sentence.dart';
import 'package:mockingbird/db/entities/subtitle.dart';
import 'package:mockingbird/tool/comm_player/comm_player_event.dart';
import 'package:mockingbird/tool/comm_player/comm_player_state.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../mobile/tab_player/subtitle/subtitle_state.dart';
import '../event_hub.dart';
import '../extensions.dart';

const double _kMaxPlaySpeed = 3.0;
const double _kMinPlaySpeed = 0.2;
const double _kStepPlaySpeed = 0.1;

mixin CommPlayerBloc on Bloc<CommPlayerEvent, CommPlayerState> {
  bool _mediaPlayingBeforeDrag = false;
  AssetEntity? media;
  final _scroller = ItemScrollController();
  SpotType? get _spot {
    if (state case CommPlayerDataStateMx data) {
      final sentenceList = data.selectedSubtitle?.sentenceList;
      final position = data.position;
      return sentenceList?.spot(position);
    } else {
      return null;
    }
  }

  SpotType? _prevSpot;
  List<StreamSubscription> subscriptionList = [];

  Future<CommPlayerState> reload(
    ({
      AssetEntity media,
      bool playing,
      int? loopIndex,
      Duration position,
      String? subtitlePath,
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
        if (state.as<CommPlayerDataStateMx>()?.loopIndex == null) {
          loopIndex = null;
        } else {
          final sentenceList = subtitleList
              .firstWhereOrNull((s) => s.name == subtitleState.as<SubtitleDataState>()?.subtitleName)
              ?.sentenceList;
          loopIndex = sentenceList?.spot(info.position)?.index;
        }
        return CommPlayerDataState(
          aspectRatio: player.value.aspectRatio,
          subtitleList: subtitleList,
          subtitleListVisible: false,
          subtitleListButtonVisible: subtitleListButtonVisible,
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
        initialAlignment: spot.alignment,
        initialIndex: spot.index,
        scroller: _scroller, 
        subtitle: subtitle,
      );
    }
    return (
      subtitleList: subtitleList,
      subtitleState: subtitleState,
      subtitleListButtonVisible: subtitleList.length > 1,
    );
  }

  void registerEvents() {
    on<CommPlayerSelectAnotherSubtitleFromListEvent>(onSelectAnotherSubtitleFromList);
    on<CommPlayerShowSubtitleListEvent>(_onShowSubtitleList);
    on<CommPlayerHideSubtitleListEvent>(_onHideSubtitleList);
    on<CommPlayerClickSentenceEvent>(_onClickSentence);
    on<CommPlayerScrollToTopEvent>(_onScrollToTop);
    on<CommPlayerScrollToBottomEvent>(_onScrollToBottom);
    on<CommPlayerScrollToPlayingSentenceEvent>(_onScrollToPlayingSentence);
    on<CommPlayerPositionChangeByPlayingEvent>(_onPositionChangeByPlaying);
    on<CommPlayerPauseEvent>(_onPause);
    on<CommPlayerPlayEvent>(_onPlay);
    on<CommPlayerToggleLoopEvent>(_onToggleLoop);
    on<CommPlayerResetSpeedEvent>(_onResetSpeed);
    on<CommPlayerIncSpeedEvent>(_onIncSpeed);
    on<CommPlayerDecSpeedEvent>(_onDecSpeed);
    on<CommPlayerMediaSliderStartChangeEvent>(_onMediaSliderStartChange);
    on<CommPlayerMediaSliderChangingEvent>(_onMediaSliderChanging);
    on<CommPlayerMediaSliderEndChangeEvent>(_onMediaSliderEndChange);
    on<CommPlayerVolumeChangeEvent>(_onVolumeChange);
    subscriptionList.addAll([
      EventHub.on<HubSubtitleChangeEvent>((event) => add(CommPlayerSelectAnotherSubtitleFromListEvent(event.name))),
    ]);
  }

  Future<void> _onPositionChangeByDragging(Duration position, Emitter<CommPlayerState> emit) async {
    if (state is! CommPlayerDataStateMx) return;
    var data = state as CommPlayerDataStateMx;
    if (data.playing) {
      data = data.copyWith(playing: false);
      emit(data);
      await data.player.pause();
    }
    await data.player.seekTo(position);
    final positionUpdated = _updatePropertiesWithPosition(position: position, emit: emit);
    if (data.loopIndex != null) {
      data = data.copyWith(loopIndex: () => _spot?.index);
      emit(state);
    }
    if (positionUpdated.sentenceChanged) {
      //handle scroll
      final spot = _spot;
      if (spot != null) {
        _scroller.safeJumpTo(spot.index, alignment: spot.alignment);
      }
    }
  }

  PositionUpdated _updatePropertiesWithPosition({required Duration position, required Emitter<CommPlayerState> emit}) {
    // var result = (mediaCompleted: false, completedLoopSentence: null, sentenceChanged: false);
    // if (state is! CommPlayerDataState) return result;

    //Fix while tap video slider, it bounce at first
    var data = state as CommPlayerDataStateMx;
    data = data.copyWith(position: position);
    emit(data);

    final mediaCompleted = position >= data.duration;

    //handle loop reseek
    final loopIndex = data.loopIndex;
    final loopSentence = loopIndex == null ? null : data.selectedSubtitle?.sentenceList.elementAtOrNull(loopIndex);
    Sentence? completedLoopSentence;
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

  void _onVolumeChange(CommPlayerVolumeChangeEvent event, Emitter<CommPlayerState> emit) async {
    if (state is! CommPlayerDataStateMx) return;
    final data = state as CommPlayerDataStateMx;
    emit(data.copyWith(volume: event.volume));
    await data.player.setVolume(event.volume);
  }

  void _onPositionChangeByPlaying(CommPlayerPositionChangeByPlayingEvent event, Emitter<CommPlayerState> emit) async {
    //Fix switch media, old listener still execute bug
    if (media == null) return;
    //Seperate dragging and playing position change listener

    var state = this.state;
    if (state is! CommPlayerDataStateMx) return;
    if (!state.playing) return;
    final positionUpdated = _updatePropertiesWithPosition(position: event.position, emit: emit);
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
        _scroller.safeScrollTo(_spot?.index, alignment: _spot?.alignment ?? 0);
      }
    }
  }

  void _onPlay(CommPlayerPlayEvent event, Emitter<CommPlayerState> emit) async {
    if (state is! CommPlayerDataStateMx) return;
    var data = state as CommPlayerDataStateMx;
    if (data.position >= data.duration) {
      const position = Duration.zero;
      data = data.copyWith(position: position);
      await data.player.seekTo(position);
    }
    emit(data.copyWith(playing: true));
    await data.player.play();
  }

  void _onPause(CommPlayerPauseEvent event, Emitter<CommPlayerState> emit) async {
    if (state is! CommPlayerDataStateMx) return;
    final data = state as CommPlayerDataStateMx;
    emit(data.copyWith(playing: false));
    await data.player.pause();
  }

  void _onToggleLoop(_, Emitter<CommPlayerState> emit) {
    if (state is! CommPlayerDataStateMx) return;
    final data = state as CommPlayerDataStateMx;
    final loopIndex = data.loopIndex == null ? _spot?.index : null;
    emit(data.copyWith(loopIndex: () => loopIndex));
  }

  void _onMediaSliderStartChange(CommPlayerMediaSliderStartChangeEvent event, Emitter<CommPlayerState> emit) async {
    final state = this.state;
    if (state is! CommPlayerDataStateMx) return;
    _mediaPlayingBeforeDrag = state.playing;
    await _onPositionChangeByDragging(event.position, emit);
  }

  void _onMediaSliderChanging(CommPlayerMediaSliderChangingEvent event, Emitter<CommPlayerState> emit) async {
    await _onPositionChangeByDragging(event.position, emit);
  }

  void _onMediaSliderEndChange(CommPlayerMediaSliderEndChangeEvent event, Emitter<CommPlayerState> emit) async {
    var state = this.state;
    if (state is! CommPlayerDataStateMx) return;
    await _onPositionChangeByDragging(event.position, emit);
    if (event.position < event.duration && _mediaPlayingBeforeDrag) {
      emit(state.copyWith(playing: true));
      await state.player.play();
    }
  }

  void _onResetSpeed(CommPlayerResetSpeedEvent event, Emitter<CommPlayerState> emit) async {
    final state = this.state;
    if (state is! CommPlayerDataStateMx) return;
    final nextSpeed = (1.0).clamp(_kMinPlaySpeed, _kMaxPlaySpeed);
    emit(state.copyWith(speed: nextSpeed));
    await state.player.setPlaybackSpeed(nextSpeed);
  }

  void _onIncSpeed(CommPlayerIncSpeedEvent event, Emitter<CommPlayerState> emit) async {
    final state = this.state;
    if (state is! CommPlayerDataStateMx) return;
    final double nextSpeed = (state.speed + _kStepPlaySpeed).clamp(_kMinPlaySpeed, _kMaxPlaySpeed).digits(1);
    emit(state.copyWith(speed: nextSpeed));
    await state.player.setPlaybackSpeed(nextSpeed);
  }

  void _onDecSpeed(CommPlayerDecSpeedEvent event, Emitter<CommPlayerState> emit) async {
    final state = this.state;
    if (state is! CommPlayerDataStateMx) return;
    final double nextSpeed = (state.speed - _kStepPlaySpeed).clamp(_kMinPlaySpeed, _kMaxPlaySpeed).digits(1);
    emit(state.copyWith(speed: nextSpeed));
    await state.player.setPlaybackSpeed(nextSpeed);
  }

  void _onScrollToTop(CommPlayerScrollToTopEvent event, Emitter<CommPlayerState> emit) {
    _scroller.safeScrollTo(0);
  }

  void _onScrollToBottom(CommPlayerScrollToBottomEvent event, Emitter<CommPlayerState> emit) {
    final dataState = state;
    if (dataState is! CommPlayerDataStateMx) return;
    final subtitle = dataState.selectedSubtitle;
    if (subtitle == null || subtitle.sentenceList.isEmpty) return;
    _scroller.safeScrollTo(subtitle.sentenceList.length - 1);
  }

  void _onScrollToPlayingSentence(CommPlayerScrollToPlayingSentenceEvent event, Emitter<CommPlayerState> emit) {
    final index = _spot?.index;
    if (index == null) return;
    _scroller.safeScrollTo(index, alignment: 0.3);
  }

  void _onClickSentence(CommPlayerClickSentenceEvent event, Emitter<CommPlayerState> emit) async {
    /*Fix loop mode, tap sentence bug
    in loop mode, you seek from s(n)->s(n+1),
    because it beyond s(n) end, so it trigger reseek to start
    same reason you seek from s(n)->s(n-1) will works perfectly,
    so in loop mode, which sentence is loop wee need to manually maintain,
    can't rely on position listening
     */
    var dataState = state;
    if (dataState is! CommPlayerDataStateMx) return;
    final sentenceIndex = dataState.selectedSubtitle?.sentenceList.firstIndexWhereOrNull(
      (sen) => sen.id == event.sentenceId,
    );
    if (sentenceIndex == null) return;
    final sentence = dataState.selectedSubtitle?.sentenceList[sentenceIndex];
    if (sentence == null) return;
    if (dataState.loopIndex != null) {
      dataState = dataState.copyWith(loopIndex: () => sentenceIndex);
    }
    EventHub.emit(HubPlayingSentenceChangeEvent(sentence.id));
    final double alignment = sentenceIndex == 0 ? 0 : 0.3;
    _scroller.safeScrollTo(sentenceIndex, alignment: alignment);
    emit(dataState.copyWith(playing: true));
    await dataState.player.seekTo(sentence.start);
    await dataState.player.play();
  }

  void _onShowSubtitleList(CommPlayerShowSubtitleListEvent event, Emitter<CommPlayerState> emit) {
    final state = this.state;
    if (state is! CommPlayerDataStateMx) return;
    emit(state.copyWith(subtitleListVisible: true));
  }

  void _onHideSubtitleList(CommPlayerHideSubtitleListEvent event, Emitter<CommPlayerState> emit) {
    final state = this.state;
    if (state is! CommPlayerDataStateMx) return;
    emit(state.copyWith(subtitleListVisible: false));
  }

  void onSelectAnotherSubtitleFromList(
    CommPlayerSelectAnotherSubtitleFromListEvent event,
    Emitter<CommPlayerState> emit,
  ) async {
    if (state case CommPlayerDataStateMx dataState) {
      final subtitle = dataState.subtitleList.firstWhereOrNull((s) => s.path == event.path);
      dataState = dataState.copyWith(
        subtitleListVisible: false,
        subtitleState: subtitle == null
            ? const SubtitleEmptyState()
            : SubtitleDataState(
                subtitle: subtitle,
                initialAlignment: _spot?.alignment ?? 0,
                initialIndex: _spot?.index ?? 0,
                scroller: _scroller,
              ),
      );
      emit(dataState);
      EventHub.emit(HubPlayingSentenceChangeEvent(_spot?.sentence.id));
    }
  }

  @override
  Future<void> close() {
    i('player bloc ${identityHashCode(this)} closed');
    for (final sub in subscriptionList) {
      sub.cancel();
    }
    state.as<CommPlayerDataStateMx>()?.player.dispose();
    return super.close();
  }
}
