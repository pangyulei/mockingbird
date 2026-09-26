import 'package:objectbox/objectbox.dart';

@Entity()
class Preference {
  @Id()
  int id;
  final bool loop;

  Preference({
    required this.id,
    required this.loop,
  });

  Preference.empty()
    : this(id: 0, loop: false, );

  Preference copyWith({
    bool? loop,
  }) {
    return Preference(
      id: id,
      loop: loop ?? this.loop,
    );
  }
}
