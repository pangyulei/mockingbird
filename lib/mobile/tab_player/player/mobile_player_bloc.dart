import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:defer/defer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:go_router/go_router.dart';
import 'package:mockingbird/db/db.dart';
import 'package:mockingbird/db/entities/mobile_media_history.dart';
import 'package:mockingbird/db/entities/subtitle.dart';
import 'package:mockingbird/mobile/app/mobile_app_route.dart';
import 'package:mockingbird/mobile/tab_player/player/mobile_player_event.dart';
import 'package:mockingbird/mobile/tab_player/player/mobile_player_state.dart';
import 'package:mockingbird/tool/comm_player/comm_player_bloc.dart';
import 'package:mockingbird/tool/comm_player/comm_player_state.dart';
import 'package:mockingbird/tool/extensions.dart';
import 'package:mockingbird/tool/subtitle_parser.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../tool/comm_player/comm_player_event.dart';
import '../../../tool/event_hub.dart';

class MobilePlayerBloc extends CommPlayerBloc {
  static final shared = MobilePlayerBloc._();

  AssetEntity? _media;
  MobilePlayerBloc._() : super() {
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

    var metadata = await DB.loadMobileMetadata();
    var history = metadata.historyList.firstWhereOrNull((h) => h.mediaId == _media?.id);
    if (history != null) {
      history = history.copyWith(subtitlePath: () => event.subtitle.path);
      await DB.updateMobileHistory(history);
    }
  }

  void _onAppPause(HubAppPauseEvent event) async {
    if (state is! CommPlayerDataState) return;
    if (_media == null) return;

    //save position
    final data = state as CommPlayerDataState;
    await _updateHistoryPosition(data.position);

    //sync to background audio player
    final playerInfo = PlayerInfo(
      media: _media!,
      duration: data.duration,
      playing: data.playing,
      position: data.position,
      speed: data.speed,
      volume: data.volume,
      loopIndex: data.loopIndex,
      sentenceList: data.subtitle?.sentenceList ?? const [],
    );
    EventHub.emit(HubSyncPlayerToBackgroundAudioEvent(playerInfo));
  }

  Future<void> _updateHistoryPosition(Duration position) async {
    final metadata = await DB.loadMobileMetadata();
    var history = metadata.historyList.firstWhereOrNull((h) => h.mediaId == _media?.id);
    if (history != null) {
      history = history.copyWith(positionMs: position.inMilliseconds);
      await DB.updateMobileHistory(history);
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
  //   var metadata = await DB.loadMetadata();
  //   metadata = metadata.copyWith(playingSubtitleName: () => subtitle.name);
  //   await DB.updateMetadata(metadata);

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
    if (state is CommPlayerDataState) {
      await _updateHistoryPosition((state as CommPlayerDataState).position);
    }

    var metadata = await DB.loadMobileMetadata();
    final mediaId = event.mediaId ?? metadata.playingMediaId;
    final media = mediaId == null ? null : await AssetEntity.fromId(mediaId);
    final mediaFile = await media?.file;
    _media = media;
    CommPlayerState commState;
    if (media == null || mediaFile == null) {
      commState = await reload(null);
      metadata = metadata.copyWith(playingMediaId: () => null);
    } else {
      var history = metadata.historyList.firstWhereOrNull((h) => h.mediaId == media.id);
      final position = history?.position ?? Duration.zero;
      final subtitlePath = history?.subtitlePath;
      final subtitle = subtitlePath == null ? null : await SubtitleParser.parsePath(subtitlePath);
      commState = await reload((
        mediaFile: mediaFile,
        mediaType: media.type,
        title: await media.titleAsync,
        playing: true,
        position: position,
        loopIndex: null,
        subtitle: subtitle,
        speed: 1,
        volume: 1,
      ));
      if (history == null) {
        history = MobileMediaHistory(
          positionMs: position.inMilliseconds,
          mediaId: media.id,
          subtitlePath: commState.as<CommPlayerDataState>()?.subtitle?.path,
        );
        metadata.historyList.add(history);
      } else {
        history = history.copyWith(subtitlePath: () => commState.as<CommPlayerDataState>()?.subtitle?.path);
        await DB.updateMobileHistory(history);
      }
      metadata = metadata.copyWith(playingMediaId: () => media.id);
    }
    await DB.updateMobileMetadata(metadata);
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
        if (state is! CommPlayerDataState) return;
        final mediaId = _media?.id;
        if (mediaId == null) return;

        //refetch media because user might deleted media while leaving the app
        final media = await AssetEntity.fromId(mediaId);
        final mediaFile = await media?.file;
        _media = media;
        final CommPlayerState newState;
        if (media == null || mediaFile == null) {
          newState = await reload(null);
          final metadata = await DB.loadMobileMetadata();
          await DB.updateMobileMetadata(metadata.copyWith(playingMediaId: () => null));
        } else {
          final data = state as CommPlayerDataState;
          newState = await reload((
            mediaFile: mediaFile,
            title: await media.titleAsync,
            mediaType: media.type,
            subtitle: data.subtitle,
            loopIndex: data.loopIndex,
            position: event.position,
            playing: event.playing,
            volume: data.volume,
            speed: data.speed,
          ));
        }
        emit(newState);
      },
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
