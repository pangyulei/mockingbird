import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockingbird/desktop/player/desktop_player_bloc.dart';

class DesktopPlayerAudioUI extends StatelessWidget {
  const DesktopPlayerAudioUI({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: DesktopPlayerBloc.shared,
      child: const SizedBox.shrink(), //TODO audio ui
    );
  }
}
