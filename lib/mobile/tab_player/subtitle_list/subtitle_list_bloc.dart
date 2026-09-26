import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockingbird/mobile/tab_player/subtitle_list/subtitle_list_event.dart';
import 'package:mockingbird/mobile/tab_player/subtitle_list/subtitle_list_state.dart';

import '../../../db/entities/subtitle.dart';
import '../../../tool/event_hub.dart';

class SubtitleListBloc extends Bloc<SubtitleListEvent,SubtitleListState> {
  final List<Subtitle> _subtitleList;
  final Subtitle? _subtitle;

  SubtitleListBloc({ required this._subtitleList, required this._subtitle})
    : super(SubtitleListState(_subtitle, _subtitleList)) {
    on<SubtitleListSelectSubtitleEvent>(_onSelectSubtitle);
  }

  void _onSelectSubtitle(
    SubtitleListSelectSubtitleEvent event,
    Emitter<SubtitleListState> emit,
  ) {
    if (_subtitle != event.subtitle) {
      EventHub.emit(HubSubtitleChangeEvent(event.subtitle));
      emit(SubtitleListState(event.subtitle, _subtitleList));
    }
    Navigator.pop(event.context);
  }
}
