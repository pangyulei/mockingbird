
import '../../../db/entities/subtitle.dart';

class PlayerSubtitleListState {
  final String? selectedSubtitleName;
  final List<Subtitle> subtitleList;

  const PlayerSubtitleListState(this.selectedSubtitleName, this.subtitleList);

  const PlayerSubtitleListState.empty() : this(null, const []);
}
