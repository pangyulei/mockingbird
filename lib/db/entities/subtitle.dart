import 'package:mockingbird/db/entities/sentence.dart';
import 'package:path/path.dart' as p;
import 'package:equatable/equatable.dart';

class Subtitle extends Equatable {
  final String path;
  final List<Sentence> sentenceList;

  String get name => p.basename(path);

  const Subtitle({required this.path, required this.sentenceList});

  @override
  List<Object?> get props => [path];
}
