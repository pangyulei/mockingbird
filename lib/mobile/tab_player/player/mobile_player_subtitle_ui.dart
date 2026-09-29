import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockingbird/mobile/tab_player/player/mobile_player_bloc.dart';
import 'package:mockingbird/mobile/tab_player/subtitle/subtitle_state.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../tool/extensions.dart';
import '../sentence_card/sentence_card_ui.dart';
import 'mobile_player_state.dart';

class MobilePlayerSubtitleUI extends StatelessWidget {
  const MobilePlayerSubtitleUI({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: MobilePlayerBloc.shared,
      child: Builder(
        builder: (context) {
          final subtitleState = context.select<MobilePlayerBloc, SubtitleState?>(
            (bloc) => bloc.state.as<MobilePlayerDataState>()?.subtitleState,
          );
          switch (subtitleState) {
            case null || SubtitleEmptyState():
              return _subtitleEmptyWidget(context);
            case SubtitleDataState data:
              return _subtitleDataWidget(data);
          }
        },
      ),
    );
  }

  Widget _subtitleDataWidget(SubtitleDataState data) {
    return ScrollablePositionedList.builder(
      key: ValueKey(data),
      itemCount: data.subtitle.sentenceList.length,
      itemScrollController: data.scroller,
      initialAlignment: data.initialAlignment,
      initialScrollIndex: data.initialIndex,
      itemBuilder: (context, i) {
        final sentenceCardBloc = context.read<MobilePlayerBloc>().sentenceCardBlocAtIndex(i);
        return SentenceCardUI(sentenceCardBloc);
      },
    );
  }

  Widget _subtitleEmptyWidget(BuildContext context) {
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
            Icon(Icons.subtitles_off_rounded, size: 48, color: colorScheme.outline.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'No Subtitles Found',
              style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.outline, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
