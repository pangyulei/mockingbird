import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mockingbird/mobile/app/mobile_app_route.dart';
import 'package:mockingbird/mobile/tab_albums/media_card/media_card_event.dart';
import 'package:mockingbird/mobile/tab_albums/media_card/media_card_state.dart';
import 'package:mockingbird/mobile/tab_albums/media_card/media_card_ui.dart';
import 'package:mockingbird/tool/event_hub.dart';
import 'package:mockingbird/tool/extensions.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../db/mobile_db.dart';


class MediaCardBloc extends MediaCardBlocType {
  final AssetEntity? _media;
  final _subscriptionList = <StreamSubscription>[];

  MediaCardBloc(this._media) : super(const MediaCardState.empty()) {
    on<MediaCardInitEvent>(_onInit);
    on<MediaCardClickEvent>(_onClick);
    on<MediaCardPlayingMediaChangeEvent>(_onPlayingMediaChange);
    _subscriptionList.addAll([
      EventHub.on<HubPlayMediaEvent>(
        (event) => add(MediaCardPlayingMediaChangeEvent(event.playingMediaId)),
      ),
    ]);
  }

  void _onPlayingMediaChange(MediaCardPlayingMediaChangeEvent event, Emitter<MediaCardState> emit) {
    emit(state.copyWith(playing: _media?.id == event.playingMediaId));
  }

  void _onClick(MediaCardClickEvent event, Emitter<MediaCardState> emit) async {
    if (_media == null) return;
    EventHub.emit(HubPlayMediaEvent(_media.id));
    event.context.go(MobileAppRoute.playerById(_media.id));
  }

  void _onInit(MediaCardInitEvent event, Emitter<MediaCardState> emit) async {
    if (_media == null) {
      return;
    }
    final title = await _media.titleAsync;
    final subtitleList = await _media.subtitleList;
    final metadata = await MobileDB.loadMetadata();
    final playing = metadata.playingMediaId == _media.id;
    emit(
      MediaCardState(
        name: title,
        type: _media.type,
        playing: playing,
        hasSubtitle: subtitleList.isNotEmpty,
      ),
    );
  }

  @override
  Future<void> close() {
    for (final sub in _subscriptionList) {
      sub.cancel();
    }
    return super.close();
  }
}
