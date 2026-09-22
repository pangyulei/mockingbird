import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockingbird/desktop/player/desktop_player_bloc.dart';
import 'package:mockingbird/desktop/player/desktop_player_empty_ui.dart';
import 'package:mockingbird/desktop/player/desktop_player_state.dart';
import 'package:mockingbird/tool/extensions.dart';
import 'package:photo_manager/photo_manager.dart';

import 'desktop_player_video_ui.dart';
import 'destop_player_audio_ui.dart';

class DesktopPlayerUI extends StatelessWidget {
  const DesktopPlayerUI({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: DesktopPlayerBloc.shared,
      child: Builder(
        builder: (context) {
          final (stateType, mediaType) = context
              .select<DesktopPlayerBloc, (Type, AssetType?)>(
                (bloc) => (
                  bloc.state.runtimeType,
                  bloc.state.as<DesktopPlayerDataState>()?.mediaType,
                ),
              );
          if (stateType == DesktopPlayerDataState && mediaType != null) {
            return mediaType == .video
                ? const DesktopPlayerVideoUI()
                : const DesktopPlayerAudioUI();
          } else {
            return const DesktopPlayerEmptyUI();
          }
        },
      ),
    );
  }
}
