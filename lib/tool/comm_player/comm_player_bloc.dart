import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:defer/defer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:mockingbird/db/entities/sentence.dart';
import 'package:mockingbird/db/entities/subtitle.dart';
import 'package:mockingbird/mobile/tab_player/sentence_card/sentence_card_bloc.dart';
import 'package:mockingbird/mobile/tab_player/sentence_card/sentence_card_event.dart';
import 'package:mockingbird/mobile/tab_player/subtitle_list/subtitle_list_bloc.dart';
import 'package:mockingbird/tool/comm_player/comm_player_event.dart';
import 'package:mockingbird/tool/comm_player/comm_player_state.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:video_player/video_player.dart';

import '../../mobile/tab_player/subtitle/subtitle_state.dart';
import '../event_hub.dart';
import '../extensions.dart';

const double _kMaxPlaySpeed = 3.0;
const double _kMinPlaySpeed = 0.2;
const double _kStepPlaySpeed = 0.1;

abstract class CommPlayerBloc extends Bloc<CommPlayerEvent, CommPlayerState> {
  bool _mediaPlayingBeforeDrag = false;
  File? mediaFile;
  final scroller = ItemScrollController();
  SpotType? _prevSpot;

  List<StreamSubscription> subscriptionList = [];
  CommPlayerBloc() : super(const CommPlayerInitState()) {
    on<CommPlayerPickSubtitleFromListEvent>(onPickSubtitleFromList);
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
      EventHub.on<HubSubtitleChangeEvent>(
        (event) => add(CommPlayerPickSubtitleFromListEvent(event.subtitle)),
      ),
    ]);
  }

  SubtitleListBloc get subtitleListBloc {
    final data = state.as<CommPlayerDataState>();
    return SubtitleListBloc(
      subtitleList: data?.subtitleList ?? [],
      subtitle: data?.subtitle,
    );
  }

  SpotType? get _spot {
    if (state case CommPlayerDataState data) {
      final sentenceList = data.subtitle?.sentenceList;
      final position = data.position;
      return sentenceList?.spot(position);
    } else {
      return null;
    }
  }

  @override
  Future<void> close() {
    i('player bloc ${identityHashCode(this)} closed');
    for (final sub in subscriptionList) {
      sub.cancel();
    }
    state.as<CommPlayerDataState>()?.player.dispose();
    return super.close();
  }

  void onPickSubtitleFromList(
    CommPlayerPickSubtitleFromListEvent event,
    Emitter<CommPlayerState> emit,
  ) async {
    if (state is! CommPlayerDataState) return;
    var data = state as CommPlayerDataState;
    final subtitle = data.subtitleList.firstWhereOrNull(
      (s) => s == event.subtitle,
    );
    data = data.rCopyWith(
      subtitleListVisible: false,
      subtitleState: subtitle == null
          ? const SubtitleEmptyState()
          : SubtitleDataState(
              subtitle: subtitle,
              initialAlignment: _spot?.alignment ?? 0,
              initialIndex: _spot?.index ?? 0,
              scroller: scroller,
            ),
    );
    emit(data);
    EventHub.emit(HubPlayingSentenceChangeEvent(_spot?.sentence.id));
  }

  Future<CommPlayerState> reload(
    ({
      File mediaFile,
      String title,
      AssetType mediaType,
      bool playing,
      int? loopIndex,
      Duration position,
      Subtitle? subtitle,
      double volume,
      double speed,
    })?
    args,
  ) async {
    final newState = await defer<CommPlayerState>(
      () async {
        mediaFile = args?.mediaFile;
      },
      () async {
        //Fix switch media, old listener still execute bug
        mediaFile = null;
        //Fix media deleted but still can here voice
        state.as<CommPlayerDataState>()?.player.dispose();
        if (args == null) {
          return const CommPlayerEmptyState();
        }
        //because of this is read and have to await, this has to be a AsyncNotifier
        final player = VideoPlayerController.file(args.mediaFile);
        await player.initialize();
        player.addListener(
          () => add(
            CommPlayerPositionChangeByPlayingEvent(player.value.position),
          ),
        );
        final (
          :subtitleList,
          :subtitleState,
          :subtitleListButtonVisible,
        ) = await reloadSubtitle(
          await args.mediaFile.subtitleList,
          args.subtitle,
          args.position,
        );
        await player.seekTo(args.position);
        if (args.playing) {
          await player.play();
        }
        final int? loopIndex;
        if (state.as<CommPlayerDataState>()?.loopIndex == null) {
          loopIndex = null;
        } else {
          final sentenceList = subtitleList
              .firstWhereOrNull(
                (s) =>
                    s.path ==
                    subtitleState.as<SubtitleDataState>()?.subtitle.path,
              )
              ?.sentenceList;
          loopIndex = sentenceList?.spot(args.position)?.index;
        }
        return CommPlayerDataState(
          aspectRatio: player.value.aspectRatio,
          subtitleList: subtitleList,
          subtitleListVisible: false,
          subtitleListButtonVisible: subtitleListButtonVisible,
          loopIndex: loopIndex,
          playing: args.playing,
          subtitleState: subtitleState,
          position: args.position,
          duration: player.value.duration,
          volume: args.volume,
          speed: args.speed,
          mediaType: args.mediaType,
          title: args.title,
          player: player,
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
  reloadSubtitle(
    List<Subtitle> subtitleList,
    Subtitle? subtitle,
    Duration position,
  ) async {
    if (!subtitleList.any((s) => s == subtitle)) {
      subtitle = subtitleList.firstOrNull;
    }
    final spot = subtitle?.sentenceList.spot(position);
    EventHub.emit(HubPlayingSentenceChangeEvent(spot?.sentence.id));
    final SubtitleState subtitleState;
    if (spot == null || subtitle == null) {
      subtitleState = const SubtitleEmptyState();
    } else {
      subtitleState = SubtitleDataState(
        initialAlignment: spot.alignment,
        initialIndex: spot.index,
        scroller: scroller,
        subtitle: subtitle,
      );
    }
    return (
      subtitleList: subtitleList,
      subtitleState: subtitleState,
      subtitleListButtonVisible: subtitleList.length > 1,
    );
  }

  SentenceCardBloc sentenceCardBlocAtIndex(int index) {
    final sentence =
        (state as CommPlayerDataState).subtitle!.sentenceList[index];
    final playing = _spot?.index == index;
    //TODO maybe no need to init playing, card bloc can read the latest playing value to emit right state
    return SentenceCardBloc(sentence, this)
      ..add(SentenceCardInitEvent(playing));
  }

  void _onClickSentence(
    CommPlayerClickSentenceEvent event,
    Emitter<CommPlayerState> emit,
  ) async {
    /*Fix loop mode, tap sentence bug
    in loop mode, you seek from s(n)->s(n+1),
    because it beyond s(n) end, so it trigger reseek to start
    same reason you seek from s(n)->s(n-1) will works perfectly,
    so in loop mode, which sentence is loop wee need to manually maintain,
    can't rely on position listening
     */
    if (state is! CommPlayerDataState) return;
    var data = state as CommPlayerDataState;
    final sentenceIndex = data.subtitle?.sentenceList.firstIndexWhereOrNull(
      (sen) => sen.id == event.sentenceId,
    );
    if (sentenceIndex == null) return;
    final sentence = data.subtitle?.sentenceList[sentenceIndex];
    if (sentence == null) return;
    if (data.loopIndex != null) {
      data = data.rCopyWith(loopIndex: () => sentenceIndex);
    }
    EventHub.emit(HubPlayingSentenceChangeEvent(sentence.id));
    final double alignment = sentenceIndex == 0 ? 0 : 0.3;
    scroller.safeScrollTo(sentenceIndex, alignment: alignment);
    emit(data.rCopyWith(playing: true));
    await data.player.seekTo(sentence.start);
    await data.player.play();
  }

  void _onDecSpeed(
    CommPlayerDecSpeedEvent event,
    Emitter<CommPlayerState> emit,
  ) async {
    if (state is! CommPlayerDataState) return;
    var data = state as CommPlayerDataState;
    final double nextSpeed = (data.speed - _kStepPlaySpeed)
        .clamp(_kMinPlaySpeed, _kMaxPlaySpeed)
        .digits(1);
    data = data.rCopyWith(speed: nextSpeed);
    emit(data);
    await data.player.setPlaybackSpeed(nextSpeed);
  }

  void _onHideSubtitleList(
    CommPlayerHideSubtitleListEvent event,
    Emitter<CommPlayerState> emit,
  ) {
    final state = this.state;
    if (state is! CommPlayerDataState) return;
    emit(state.rCopyWith(subtitleListVisible: false));
  }

  void _onIncSpeed(
    CommPlayerIncSpeedEvent event,
    Emitter<CommPlayerState> emit,
  ) async {
    if (state is! CommPlayerDataState) return;
    var data = state as CommPlayerDataState;
    final double nextSpeed = (data.speed + _kStepPlaySpeed)
        .clamp(_kMinPlaySpeed, _kMaxPlaySpeed)
        .digits(1);
    data = data.rCopyWith(speed: nextSpeed);
    emit(data);
    await data.player.setPlaybackSpeed(nextSpeed);
  }

  void _onMediaSliderChanging(
    CommPlayerMediaSliderChangingEvent event,
    Emitter<CommPlayerState> emit,
  ) async {
    await _onPositionChangeByDragging(event.position, emit);
  }

  void _onMediaSliderEndChange(
    CommPlayerMediaSliderEndChangeEvent event,
    Emitter<CommPlayerState> emit,
  ) async {
    if (state is! CommPlayerDataState) return;
    var data = state as CommPlayerDataState;
    await _onPositionChangeByDragging(event.position, emit);
    if (event.position < event.duration && _mediaPlayingBeforeDrag) {
      data = data.rCopyWith(playing: true);
      emit(data);
      await data.player.play();
    }
  }

  void _onMediaSliderStartChange(
    CommPlayerMediaSliderStartChangeEvent event,
    Emitter<CommPlayerState> emit,
  ) async {
    final state = this.state;
    if (state is! CommPlayerDataState) return;
    _mediaPlayingBeforeDrag = state.playing;
    await _onPositionChangeByDragging(event.position, emit);
  }

  void _onPause(
    CommPlayerPauseEvent event,
    Emitter<CommPlayerState> emit,
  ) async {
    if (state is! CommPlayerDataState) return;
    final data = state as CommPlayerDataState;
    emit(data.rCopyWith(playing: false));
    await data.player.pause();
  }

  void _onPlay(CommPlayerPlayEvent event, Emitter<CommPlayerState> emit) async {
    if (state is! CommPlayerDataState) return;
    var data = state as CommPlayerDataState;
    if (data.position >= data.duration) {
      const position = Duration.zero;
      data = data.rCopyWith(position: position);
      await data.player.seekTo(position);
    }
    emit(data.rCopyWith(playing: true));
    await data.player.play();
  }

  Future<void> _onPositionChangeByDragging(
    Duration position,
    Emitter<CommPlayerState> emit,
  ) async {
    if (state is! CommPlayerDataState) return;
    var data = state as CommPlayerDataState;
    if (data.playing) {
      data = data.rCopyWith(playing: false);
      emit(data);
      await data.player.pause();
    }
    await data.player.seekTo(position);
    final playerProperties = _updatePropertiesWithPosition(
      position: position,
      emit: emit,
    );
    if (data.loopIndex != null) {
      data = data.rCopyWith(loopIndex: () => _spot?.index);
      emit(state);
    }
    if (playerProperties.sentenceChanged) {
      //handle scroll
      final spot = _spot;
      if (spot != null) {
        scroller.safeJumpTo(spot.index, alignment: spot.alignment);
      }
    }
  }

  void _onPositionChangeByPlaying(
    CommPlayerPositionChangeByPlayingEvent event,
    Emitter<CommPlayerState> emit,
  ) async {
    //Fix switch media, old listener still execute bug
    if (mediaFile == null) return;
    //Seperate dragging and playing position change listener

    var state = this.state;
    if (state is! CommPlayerDataState) return;
    if (!state.playing) return;
    final playerProperties = _updatePropertiesWithPosition(
      position: event.position,
      emit: emit,
    );
    if (playerProperties.mediaCompleted) {
      //audo re-play media
      state = state.rCopyWith(playing: true);
      emit(state);
      await state.player.seekTo(Duration.zero);
      await state.player.play();
    }
    final completedLoopSentence = playerProperties.completedLoopSentence;
    if (completedLoopSentence != null) {
      //reseek loop sentence
      await state.player.seekTo(completedLoopSentence.start);
    }
    if (playerProperties.sentenceChanged) {
      //handle scroll
      if (state.loopIndex == null) {
        //playing auto scroll to next sentence, not for loop mode
        scroller.safeScrollTo(_spot?.index, alignment: _spot?.alignment ?? 0);
      }
    }
  }

  void _onResetSpeed(
    CommPlayerResetSpeedEvent event,
    Emitter<CommPlayerState> emit,
  ) async {
    if (state is! CommPlayerDataState) return;
    var data = state as CommPlayerDataState;
    final nextSpeed = (1.0).clamp(_kMinPlaySpeed, _kMaxPlaySpeed);
    data = data.rCopyWith(speed: nextSpeed);
    emit(data);
    await data.player.setPlaybackSpeed(nextSpeed);
  }

  void _onScrollToBottom(
    CommPlayerScrollToBottomEvent event,
    Emitter<CommPlayerState> emit,
  ) {
    if (state is! CommPlayerDataState) return;
    final data = state as CommPlayerDataState;
    final subtitle = data.subtitle;
    if (subtitle == null || subtitle.sentenceList.isEmpty) return;
    scroller.safeScrollTo(subtitle.sentenceList.length - 1);
  }

  void _onScrollToPlayingSentence(
    CommPlayerScrollToPlayingSentenceEvent event,
    Emitter<CommPlayerState> emit,
  ) {
    final index = _spot?.index;
    if (index == null) return;
    scroller.safeScrollTo(index, alignment: 0.3);
  }

  void _onScrollToTop(
    CommPlayerScrollToTopEvent event,
    Emitter<CommPlayerState> emit,
  ) {
    scroller.safeScrollTo(0);
  }

  void _onShowSubtitleList(
    CommPlayerShowSubtitleListEvent event,
    Emitter<CommPlayerState> emit,
  ) {
    final state = this.state;
    if (state is! CommPlayerDataState) return;
    emit(state.rCopyWith(subtitleListVisible: true));
  }

  void _onToggleLoop(_, Emitter<CommPlayerState> emit) {
    if (state is! CommPlayerDataState) return;
    final data = state as CommPlayerDataState;
    final loopIndex = data.loopIndex == null ? _spot?.index : null;
    emit(data.rCopyWith(loopIndex: () => loopIndex));
  }

  void _onVolumeChange(
    CommPlayerVolumeChangeEvent event,
    Emitter<CommPlayerState> emit,
  ) async {
    if (state is! CommPlayerDataState) return;
    final data = state as CommPlayerDataState;
    emit(data.rCopyWith(volume: event.volume));
    await data.player.setVolume(event.volume);
  }

  PlayerProperties _updatePropertiesWithPosition({
    required Duration position,
    required Emitter<CommPlayerState> emit,
  }) {
    // var result = (mediaCompleted: false, completedLoopSentence: null, sentenceChanged: false);
    // if (state is! CommPlayerDataState) return result;

    //Fix while tap video slider, it bounce at first
    var data = state as CommPlayerDataState;
    data = data.rCopyWith(position: position);
    emit(data);

    final mediaCompleted = position >= data.duration;

    //handle loop reseek
    final loopIndex = data.loopIndex;
    final loopSentence = loopIndex == null
        ? null
        : data.subtitle?.sentenceList.elementAtOrNull(loopIndex);
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
}
