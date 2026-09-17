import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockingbird/mobile/tab_player/subtitle_list/mobile_subtitle_list_event.dart';
import 'package:mockingbird/mobile/tab_player/subtitle_list/mobile_subtitle_list_state.dart';
import 'package:mockingbird/mobile/tab_player/subtitle_list/mobile_subtitle_list_ui.dart';

import '../../../db/entities/subtitle.dart';
import '../../../tool/event_hub.dart';

class MobileSubtitleListBloc extends MobileSubtitleListBlocType {
  final List<Subtitle> _subtitleList;
  final String? _selectedSubtitleName;

  MobileSubtitleListBloc(this._subtitleList, this._selectedSubtitleName)
    : super(MobileSubtitleListState(_selectedSubtitleName, _subtitleList)) {
    on<MobileSubtitleListSelectNameEvent>(_onSelectName);
  }

  void _onSelectName(
    MobileSubtitleListSelectNameEvent event,
    Emitter<MobileSubtitleListState> emit,
  ) {
    if (_selectedSubtitleName != event.name) {
      EventHub.emit(HubSubtitleChangeEvent(event.name));
      emit(MobileSubtitleListState(event.name, _subtitleList));
    }
    Navigator.pop(event.context);
  }
}
