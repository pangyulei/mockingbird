import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockingbird/desktop/player/desktop_player_bloc.dart';
import 'package:mockingbird/mobile/tab_player/sentence_card/sentence_card_ui.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../mobile/tab_player/subtitle/subtitle_state.dart';
import '../../tool/extensions.dart';
import '../player/desktop_player_state.dart';

class DesktopSubtitleUI extends StatelessWidget {
  const DesktopSubtitleUI({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: DesktopPlayerBloc.shared,
      child: Builder(
        builder: (context) {
          final subtitleState = context
              .select<DesktopPlayerBloc, SubtitleState?>(
                (bloc) =>
                    bloc.state.as<DesktopPlayerDataState>()?.subtitleState,
              );
          switch (subtitleState) {
            case null || SubtitleEmptyState():
              return _noSubtitle();
            case SubtitleDataState data:
              return ScrollablePositionedList.builder(
                key: ValueKey(data),
                itemCount: data.sentenceList.length,
                itemScrollController: data.scroller,
                initialAlignment: data.initialAlignment,
                initialScrollIndex: data.initialIndex,
                itemBuilder: (context, i) {
                  final sentenceCardBloc = context
                      .read<DesktopPlayerBloc>()
                      .sentenceCardBlocAtIndex(i);
                  return SentenceCardUI(sentenceCardBloc);
                },
              );
          }
        },
      ),
    );
  }

  Widget _noSubtitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(1, 8, 8, 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {},
          child: glassContainer(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.subtitles_off_rounded,
                    size: 48,
                    color: kSecondaryWhite,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Subtitles Found',
                    style: mbTextStyle(
                      color: kSecondaryWhite,
                      size: 16,
                      weight: .bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
