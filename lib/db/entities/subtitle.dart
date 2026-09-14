import 'package:mockingbird/db/entities/sentence.dart';
import 'package:path/path.dart' as p;

class Subtitle {
  final String path;
  final List<SentenceEntity> sentenceList;

  String get name => p.basename(path);

  const Subtitle({required this.path, required this.sentenceList});
}
