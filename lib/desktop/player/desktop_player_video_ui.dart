import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marquee/marquee.dart';
import 'package:mockingbird/desktop/player/desktop_player_bloc.dart';
import 'package:mockingbird/desktop/player/desktop_player_event.dart';
import 'package:mockingbird/desktop/player/desktop_player_state.dart';
import 'package:mockingbird/tool/extensions.dart';
import 'package:video_player/video_player.dart';

import '../../mobile/tab_player/subtitle/subtitle_state.dart';

const double kDesktopPlayerMinWidth = 600;
const double kDesktopSubtitleMinWidth = 300;
const double kDesktopMainWindowMinHeight = 500;
const double kDesktopMainWindowDividerThickness = 6; // 稍微加粗一点，方便鼠标抓取

class DesktopPlayerVideoUI extends StatelessWidget {
  const DesktopPlayerVideoUI({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: DesktopPlayerBloc.shared,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _appBar(context),
          Expanded(child: Center(child: _videoDisplayer(context))),
          _controlBar(context),
        ],
      ),
    );
  }

  // Widget _home() {
  //   //Theme.of(context).scaffoldBackgroundColor
  //   return Scaffold(
  //     body: MultiSplitViewTheme(
  //       data: MultiSplitViewThemeData(
  //         dividerThickness: kDesktopMainWindowDividerThickness,
  //         dividerPainter: DividerPainters.grooved1(
  //           color: kPrimaryGreen,
  //           highlightedColor: kPrimaryGreen,
  //           thickness: 4,
  //         ),
  //       ),
  //       child: imageContainer(
  //         Image.asset('assets/desktop/main_window_background.jpg').image,
  //         child: Builder(
  //           builder: (context) {
  //             final splitter = context
  //                 .select<DesktopMainWindowBloc, MultiSplitViewController?>(
  //                   (bloc) =>
  //               bloc.state.as<DesktopMainWindowDataState>()?.splitter,
  //             );
  //             if (splitter == null) return const SizedBox.shrink();
  //             return MultiSplitView(
  //               controller: splitter,
  //               axis: Axis.horizontal,
  //             );
  //           },
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _appBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withValues(alpha: 0.6),
      child: Row(
        children: [
          Expanded(
            child: Builder(
              builder: (context) {
                final title = context.select<DesktopPlayerBloc, String>(
                  (bloc) =>
                      bloc.state.as<DesktopPlayerDataState>()?.title ?? '',
                );
                return SizedBox(
                  height: 24,
                  child: title.isEmpty
                      ? const Text('')
                      : Marquee(
                          text: title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          scrollAxis: Axis.horizontal,
                          blankSpace: 50,
                          velocity: 30,
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _videoDisplayer(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Builder(
          builder: (context) {
            final aspectRatio = context.select<DesktopPlayerBloc, double>(
              (bloc) =>
                  bloc.state.as<DesktopPlayerDataState>()?.aspectRatio ??
                  16 / 9,
            );
            return AspectRatio(aspectRatio: aspectRatio, child: _player());
          },
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 8,
          // child: Expanded(child: _progressSlider(context)),
          child: _progressSlider(context),
        ),
      ],
    );
  }

  Widget _player() {
    return Builder(
      builder: (context) {
        final player = context
            .select<DesktopPlayerBloc, VideoPlayerController?>(
              (bloc) => bloc.state.as<DesktopPlayerDataState>()?.player,
            );
        if (player == null) return const SizedBox.shrink();
        return VideoPlayer(player);
      },
    );
  }

  Widget _progressSlider(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3.0,
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: Colors.white24,
        thumbColor: Colors.white,
        thumbSize: WidgetStateProperty.all(const Size(14, 14)),
      ),
      child: Builder(
        builder: (context) {
          final (position, duration) = context
              .select<DesktopPlayerBloc, (Duration, Duration)>(
                (bloc) => (
                  bloc.state.as<DesktopPlayerDataState>()?.position ??
                      Duration.zero,
                  bloc.state.as<DesktopPlayerDataState>()?.duration ??
                      Duration.zero,
                ),
              );
          final max = duration.inMilliseconds.toDouble();
          final val = position.inMilliseconds.clamp(0, max).toDouble();
          return Slider(
            allowedInteraction: SliderInteraction.slideThumb,
            value: val,
            max: max,
            onChangeStart: (val) {
              context.read<DesktopPlayerBloc>().add(
                DesktopPlayerMediaSliderStartChangeEvent(
                  Duration(milliseconds: val.toInt()),
                  duration,
                ),
              );
            },
            onChanged: (val) {
              context.read<DesktopPlayerBloc>().add(
                DesktopPlayerMediaSliderChangingEvent(
                  Duration(milliseconds: val.toInt()),
                  duration,
                ),
              );
            },
            onChangeEnd: (val) {
              context.read<DesktopPlayerBloc>().add(
                DesktopPlayerMediaSliderEndChangeEvent(
                  Duration(milliseconds: val.toInt()),
                  duration,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _controlBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Builder(
        builder: (context) {
          final subtitleListButtonVisible = context
              .select<DesktopPlayerBloc, bool>(
                (bloc) =>
                    bloc.state
                        .as<DesktopPlayerDataState>()
                        ?.subtitleListButtonVisible ??
                    false,
              );
          return Row(
            children: [
              _playOrPauseButton(context),
              const SizedBox(width: 16),
              _loopButton(context),
              if (subtitleListButtonVisible) ...[
                const SizedBox(width: 16),
                _subtitleListButton(context),
              ],
              const Spacer(),
              _speedDownButton(),
              const SizedBox(width: 8),
              _speedLabel(context),
              const SizedBox(width: 8),
              _speedUpButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _playOrPauseButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Builder(
      builder: (context) {
        final playing = context.select<DesktopPlayerBloc, bool>(
          (bloc) => bloc.state.as<DesktopPlayerDataState>()?.playing ?? false,
        );
        return IconButton.filled(
          onPressed: () {
            if (playing) {
              context.read<DesktopPlayerBloc>().add(
                const DesktopPlayerPauseEvent(),
              );
            } else {
              context.read<DesktopPlayerBloc>().add(
                const DesktopPlayerPlayEvent(),
              );
            }
          },
          icon: Icon(
            playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 20,
          ),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
        );
      },
    );
  }

  Widget _loopButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Builder(
      builder: (context) {
        final hasSubtitle = context.select<DesktopPlayerBloc, bool>(
          (bloc) =>
              bloc.state.as<DesktopPlayerDataState>()?.subtitleState
                  is SubtitleDataState,
        );
        if (!hasSubtitle) return const SizedBox.shrink();
        final loop = context.select<DesktopPlayerBloc, bool>(
          (bloc) => bloc.state.as<DesktopPlayerDataState>()?.loopIndex != null,
        );
        return IconButton(
          onPressed: () {
            context.read<DesktopPlayerBloc>().add(
              const DesktopPlayerToggleLoopEvent(),
            );
          },
          icon: Icon(
            loop ? Icons.repeat_one_rounded : Icons.repeat_rounded,
            color: loop ? colorScheme.primary : colorScheme.outline,
            size: 20,
          ),
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
        );
      },
    );
  }

  Widget _subtitleListButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: () {
        context.read<DesktopPlayerBloc>().add(
          const DesktopPlayerShowSubtitleListEvent(),
        );
      },
      icon: Icon(Icons.subtitles_rounded, color: colorScheme.outline, size: 20),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
    );
  }

  Widget _speedDownButton() {
    return Builder(
      builder: (context) => IconButton(
        onPressed: () {
          context.read<DesktopPlayerBloc>().add(
            const DesktopPlayerDecSpeedEvent(),
          );
        },
        icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
        color: Theme.of(context).colorScheme.outline,
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _speedUpButton() {
    return Builder(
      builder: (context) => IconButton(
        onPressed: () {
          context.read<DesktopPlayerBloc>().add(
            const DesktopPlayerIncSpeedEvent(),
          );
        },
        icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
        color: Theme.of(context).colorScheme.outline,
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _speedLabel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Builder(
      builder: (context) {
        final speed = context.select<DesktopPlayerBloc, double>(
          (bloc) => bloc.state.as<DesktopPlayerDataState>()?.speed ?? 1,
        );
        return GestureDetector(
          onTap: () => context.read<DesktopPlayerBloc>().add(
            const DesktopPlayerResetSpeedEvent(),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${speed}x',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        );
      },
    );
  }
}
