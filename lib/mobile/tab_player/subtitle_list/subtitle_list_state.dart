
import '../../../db/entities/subtitle.dart';

class SubtitleListState {
  final Subtitle? subtitle;
  final List<Subtitle> subtitleList;

  const SubtitleListState(this.subtitle, this.subtitleList);

  const SubtitleListState.empty() : this(null, const []);
}
