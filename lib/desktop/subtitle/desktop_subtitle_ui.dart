import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockingbird/desktop/player/desktop_player_bloc.dart';
import 'package:mockingbird/mobile/tab_player/sentence_card/sentence_card_ui.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../tool/extensions.dart';
import '../player/desktop_player_state.dart';
import '../../mobile/tab_player/subtitle/subtitle_state.dart';

class DesktopSubtitleUI extends StatelessWidget {
  const DesktopSubtitleUI({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: DesktopPlayerBloc.shared,
      child: Builder(builder: (context) {
        final subtitleState = context
            .select<DesktopPlayerBloc, SubtitleState?>((bloc) => bloc.state.as<DesktopPlayerDataState>()?.subtitleState);
        switch (subtitleState) {
          case null || SubtitleEmptyState():
            return _noSubtitle(context);
          case SubtitleDataState data:
            return ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: ScrollablePositionedList.builder(
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
                ),
              );
        }
      }),
    );
  }


  Widget _noSubtitle(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: () {
        // => _onAddSubtitle(ref)
      },
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.subtitles_off_rounded,
              size: 48,
              color: colorScheme.outline.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No Subtitles Found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.outline,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
