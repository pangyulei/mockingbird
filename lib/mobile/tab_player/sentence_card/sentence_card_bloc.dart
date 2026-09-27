import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockingbird/mobile/tab_player/sentence_card/sentence_card_event.dart';
import 'package:mockingbird/mobile/tab_player/sentence_card/sentence_card_state.dart';
import 'package:mockingbird/tool/comm_player/comm_player_bloc.dart';
import 'package:mockingbird/tool/event_hub.dart';
import 'package:mockingbird/tool/extensions.dart';

import '../../../db/entities/sentence.dart';
import '../../../tool/comm_player/comm_player_event.dart';

class SentenceCardBloc extends Bloc<SentenceCardEvent, SentenceCardState> {
  final _subList = <StreamSubscription>[];
  final Sentence _sentence;
  final CommPlayerBloc _playerBloc;

  SentenceCardBloc(this._sentence, this._playerBloc)
    : super(const SentenceCardState.empty()) {
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
    // event.context.read<CommPlayerBloc>().add(
    //   CommPlayerClickSentenceEvent(_sentence.id),
    // );
    _playerBloc.add(CommPlayerClickSentenceEvent(_sentence.id));
  }

  @override
  Future<void> close() {
    for (final sub in _subList) {
      sub.cancel();
    }
    return super.close();
  }

  void _onInit(SentenceCardInitEvent event, Emitter<SentenceCardState> emit) {
    emit(
      SentenceCardState(
        text: _sentence.text,
        period: '${_sentence.start.desc} - ${_sentence.end.desc}',
        playing: event.playing,
      ),
    );
  }

  void _onPlayingSentenceChange(
    SentenceCardPlayingSentenceChangeEvent event,
    Emitter<SentenceCardState> emit,
  ) {
    emit(state.copyWith(playing: _sentence.id == event.playingSentenceId));
  }
}
