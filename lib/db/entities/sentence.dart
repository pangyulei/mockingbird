
class SentenceEntity {
  final String id;
  final Duration start;
  final Duration end;
  final String text;

  const SentenceEntity({
    required this.id,
    required this.start,
    required this.end,
    required this.text,
  });

  @override
  String toString() {
    return text;
  }
}