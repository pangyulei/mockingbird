import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockingbird/mobile/tab_player/player/mobile_player_event.dart';
import 'package:mockingbird/mobile/tab_player/player/mobile_player_ui.dart';
import 'package:mockingbird/mobile/tab_player/sentence_card/sentence_card_event.dart';
import 'package:mockingbird/mobile/tab_player/sentence_card/sentence_card_state.dart';
import 'package:mockingbird/mobile/tab_player/sentence_card/sentence_card_ui.dart';
import 'package:mockingbird/tool/event_hub.dart';
import 'package:mockingbird/tool/extensions.dart';

import '../../../db/entities/sentence.dart';

class SentenceCardBloc extends SentenceCardBlocType {
  final _subList = <StreamSubscription>[];
  final SentenceEntity? _sentence;

  SentenceCardBloc(this._sentence) : super(const SentenceCardState.empty()) {
    on<SentenceCardInitEvent>(_onInit);
    on<SentenceCardPlayingSentenceChangeEvent>(_onPlayingSentenceChange);
    on<SentenceCardClickEvent>(_onClick);
    _subList.add(
      EventHub.on<HubPlayingSentenceChangeEvent>(
        (event) => add(
          SentenceCardPlayingSentenceChangeEvent(event.playingSentenceId),
        ),
      ),
    );
  }

  void _onClick(SentenceCardClickEvent event, Emitter<SentenceCardState> emit) {
    final sentenceId = _sentence?.id;
    if (sentenceId == null) return;
    event.context.read<PlayerBlocType>().add(
      MobilePlayerClickSentenceEvent(sentenceId),
    );
  }

  @override
  Future<void> close() {
    for (final sub in _subList) {
      sub.cancel();
    }
    return super.close();
  }

  void _onInit(SentenceCardInitEvent event, Emitter<SentenceCardState> emit) {
    final sentence = _sentence;
    if (sentence == null) return;
    emit(
      SentenceCardState(
        text: sentence.text,
        period: '${sentence.start.desc} - ${sentence.end.desc}',
        playing: event.playing,
      ),
    );
  }

  void _onPlayingSentenceChange(
    SentenceCardPlayingSentenceChangeEvent event,
    Emitter<SentenceCardState> emit,
  ) {
    emit(state.copyWith(playing: _sentence?.id == event.playingSentenceId));
  }
}
