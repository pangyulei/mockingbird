import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockingbird/desktop/player/desktop_player_bloc.dart';
import 'package:mockingbird/mobile/tab_player/sentence_card/sentence_card_ui.dart';
import 'package:mockingbird/mobile/tab_player/player/mobile_player_state.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../player/desktop_player_state.dart';

class DesktopSubtitleUI extends StatelessWidget {
  const DesktopSubtitleUI({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: SharedDesktopPlayerBloc.instance,
      child: Scaffold(
        backgroundColor: const Color(0xFF0E1621),
        body: BlocBuilder<DesktopPlayerBloc, DesktopPlayerState>(
          builder: (context, state) {
            if (state is DesktopPlayerDataState) {
              if (state.subtitleState is SubtitleDataState) {
                final subtitleState = state.subtitleState as SubtitleDataState;
                return ScrollablePositionedList.builder(
                  key: ValueKey(subtitleState.subtitleName),
                  itemCount: subtitleState.sentenceList.length,
                  itemScrollController: state.scroller,
                  initialAlignment: subtitleState.initialAlignment,
                  initialScrollIndex: subtitleState.initialIndex,
                  itemBuilder: (context, i) {
                    final sentenceCardBloc = context.read<DesktopPlayerBloc>().sentenceCardBlocAtIndex(i);
                    return SentenceCardUI(sentenceCardBloc);
                  },
                );
              } else if (state.subtitleState is SubtitleEmptyState) {
                return const Center(child: Text('No Subtitles Found'));
              }
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
