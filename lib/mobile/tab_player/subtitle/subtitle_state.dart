
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../db/entities/sentence.dart';

sealed class SubtitleState {
  const SubtitleState();
}

class SubtitleEmptyState extends SubtitleState {
  const SubtitleEmptyState();
}

class SubtitleDataState extends SubtitleState {
  final String subtitleName;
  final List<SentenceEntity> sentenceList;
  final double initialAlignment;
  final int initialIndex;
  final ItemScrollController scroller;

  const SubtitleDataState({
    required this.scroller,
    required this.subtitleName,
    required this.sentenceList,
    required this.initialAlignment,
    required this.initialIndex,
  });
}