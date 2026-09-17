
import '../../../db/entities/subtitle.dart';

class MobileSubtitleListState {
  final String? selectedSubtitleName;
  final List<Subtitle> subtitleList;

  const MobileSubtitleListState(this.selectedSubtitleName, this.subtitleList);

  const MobileSubtitleListState.empty() : this(null, const []);
}
