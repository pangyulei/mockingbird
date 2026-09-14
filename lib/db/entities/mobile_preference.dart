import 'package:objectbox/objectbox.dart';

@Entity()
class MobilePreference {
  @Id()
  int id;
  final bool loop;

  MobilePreference({
    required this.id,
    required this.loop,
  });

  MobilePreference.empty()
    : this(id: 0, loop: false, );

  MobilePreference copyWith({
    bool? loop,
  }) {
    return MobilePreference(
      id: id,
      loop: loop ?? this.loop,
    );
  }
}
