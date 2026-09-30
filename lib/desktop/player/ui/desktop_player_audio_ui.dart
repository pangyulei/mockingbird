import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockingbird/desktop/player/desktop_player_bloc.dart';
import 'package:mockingbird/desktop/player/desktop_player_event.dart';
import 'package:mockingbird/desktop/player/desktop_player_state.dart';
import 'package:mockingbird/desktop/player/ui/desktop_player_subtitle_list.dart';
import 'package:mockingbird/tool/comm_player/comm_player_event.dart';
import 'package:mockingbird/tool/comm_player/comm_player_state.dart';
import 'package:mockingbird/tool/extensions.dart';

class DesktopPlayerAudioUI extends StatelessWidget {
  const DesktopPlayerAudioUI({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: DesktopPlayerBloc.shared,
      child: BlocListener<DesktopPlayerBloc, CommPlayerState>(
        listenWhen: (previous, current) =>
            (previous is! CommPlayerDataState || !previous.subtitleListVisible) &&
            (current is CommPlayerDataState && current.subtitleListVisible),
        listener: (context, state) => showSubtitleList(context),
        child: Scaffold(
          body: ImageContainer(
            image: Image.asset('assets/desktop/main_window_background.jpg').image,
            padding: const EdgeInsets.all(8),
            child: Column(children: [_displayerWidget(), const SizedBox(height: 8), _subtitleWidget()]),
          ),
        ),
      ),
    );
  }

  Widget _subtitleWidget() {
    return const SizedBox.shrink();
  }

  Widget _displayerWidget() {
    return GlassContainer(
      child: Column(
        mainAxisAlignment: .center,
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(8, 8, 20, 0), child: _volumeWidget()),
          const SizedBox(height: 8),
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12), child: _progressSlider()),
        ],
      ),
    );
  }

  Widget _volumeWidget() {
    return Row(
      children: [
        _volumeButton(),
        const SizedBox(width: 20),
        Expanded(child: _volumeSlider()),
      ],
    );
  }

  Widget _volumeButton() {
    return Builder(
      builder: (context) {
        final muting = context.select<DesktopPlayerBloc, bool>(
          (bloc) => bloc.state.as<DesktopPlayerDataState>()?.muting ?? false,
        );
        return IconButton(
          onPressed: () {
            context.read<DesktopPlayerBloc>().add(const DesktopPlayerToggleMuteEvent());
          },
          icon: Icon(muting ? Icons.volume_off : Icons.volume_up, size: 32),
          color: kPrimaryColor,
          style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
        );
      },
    );
  }

  Widget _volumeSlider() {
    return SliderTheme(
      data: const SliderThemeData(
        trackHeight: 3.0,
        activeTrackColor: kPrimaryColor,
        inactiveTrackColor: Colors.white,
        thumbColor: kPrimaryColor,
        padding: EdgeInsets.zero,
      ),
      child: Builder(
        builder: (context) {
          const double maxVolume = 1;
          final (muting, volume) = context.select<DesktopPlayerBloc, (bool, double)>((bloc) {
            final data = bloc.state.as<DesktopPlayerDataState>();
            return (data?.muting ?? false, data?.volume ?? maxVolume);
          });
          return Slider(
            value: muting ? 0 : volume,
            max: maxVolume,
            onChanged: (volume) {
              context.read<DesktopPlayerBloc>().add(CommPlayerVolumeChangeEvent(volume));
            },
          );
        },
      ),
    );
  }

  Widget _progressSlider() {
    return SliderTheme(
      data: const SliderThemeData(
        trackHeight: 3.0,
        activeTrackColor: kPrimaryColor,
        inactiveTrackColor: kPrimaryTextColor,
        thumbColor: kPrimaryColor,
        padding: EdgeInsets.zero,
        // thumbSize: WidgetStateProperty.all(const Size(14, 14)),
      ),
      child: Builder(
        builder: (context) {
          final (position, duration) = context.select<DesktopPlayerBloc, (Duration, Duration)>(
            (bloc) => (
              bloc.state.as<CommPlayerDataState>()?.position ?? Duration.zero,
              bloc.state.as<CommPlayerDataState>()?.duration ?? Duration.zero,
            ),
          );
          final max = duration.inMilliseconds.toDouble();
          final val = position.inMilliseconds.clamp(0, max).toDouble();
          return Slider(
            allowedInteraction: .tapAndSlide,
            value: val,
            max: max,
            onChangeStart: (val) {
              context.read<DesktopPlayerBloc>().add(
                CommPlayerMediaSliderStartChangeEvent(Duration(milliseconds: val.toInt()), duration),
              );
            },
            onChanged: (val) {
              context.read<DesktopPlayerBloc>().add(
                CommPlayerMediaSliderChangingEvent(Duration(milliseconds: val.toInt()), duration),
              );
            },
            onChangeEnd: (val) {
              context.read<DesktopPlayerBloc>().add(
                CommPlayerMediaSliderEndChangeEvent(Duration(milliseconds: val.toInt()), duration),
              );
            },
          );
        },
      ),
    );
  }
}
