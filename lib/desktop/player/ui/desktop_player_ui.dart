import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockingbird/desktop/player/desktop_player_bloc.dart';
import 'package:mockingbird/desktop/player/desktop_player_event.dart';
import 'package:mockingbird/desktop/player/ui/desktop_player_empty_ui.dart';
import 'package:mockingbird/tool/comm_player/comm_player_state.dart';
import 'package:mockingbird/tool/extensions.dart';
import 'package:photo_manager/photo_manager.dart';

import 'desktop_player_audio_ui.dart';
import 'desktop_player_video_ui.dart';

class DesktopPlayerUI extends StatelessWidget {
  const DesktopPlayerUI({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: DesktopPlayerBloc.shared..add(const DesktopPlayerInitEvent()),
      child: Builder(
        builder: (context) {
          final mediaType = context.select<DesktopPlayerBloc, AssetType?>(
            (bloc) => bloc.state.as<CommPlayerDataState>()?.mediaType,
          );
          if (mediaType == null) {
            return const DesktopPlayerEmptyUI();
          } else {
            return mediaType == .video
                ? const DesktopPlayerVideoUI()
                : const DesktopPlayerAudioUI();
          }
        },
      ),
    );
  }
}
