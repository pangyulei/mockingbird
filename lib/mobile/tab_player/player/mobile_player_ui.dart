import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marquee/marquee.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:mockingbird/mobile/tab_player/player/mobile_player_bloc.dart';
import 'package:mockingbird/mobile/tab_player/player/mobile_player_event.dart';
import 'package:mockingbird/mobile/tab_player/player/mobile_player_state.dart';
import 'package:mockingbird/mobile/tab_player/subtitle_list/mobile_subtitle_list_ui.dart';
import 'package:mockingbird/tool/extensions.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

import '../subtitle/mobile_subtitle_ui.dart';
import '../subtitle/subtitle_state.dart';


class MobilePlayerUI extends StatelessWidget {
  final MobilePlayerBloc _bloc;
  const MobilePlayerUI(this._bloc, {super.key});

  @override
  Widget build(BuildContext context) {
    i('player ui building');
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<MobilePlayerBloc, MobilePlayerState>(
        listenWhen: (previous, current) {
          return (previous is! MobilePlayerDataState || previous.subtitleListVisible == false) && current is MobilePlayerDataState && current.subtitleListVisible;
        },
        listener: (context, state) => _showSubtitleList(context),
        child: Builder(
          builder: (context) {
            final stateType = context.select<MobilePlayerBloc, Type>(
              (bloc) => bloc.state.runtimeType,
            );
            switch (stateType) {
              case MobilePlayerInitState:
                return _pageForInit();
              case MobilePlayerEmptyState:
                return _pageForEmpty(context);
              case MobilePlayerDataState:
                return _pageForData(context);
              default:
                assert(false, 'stateType $stateType missed');
                return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }

  void _showSubtitleList(BuildContext context) {
    final subtitleListBloc = context
        .read<MobilePlayerBloc>()
        .subtitleListBlocType;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return MobileSubtitleListUI(subtitleListBloc);
      },
    ).whenComplete(() {
      if (context.mounted) {
        context.read<MobilePlayerBloc>().add(
          const MobilePlayerHideSubtitleListEvent(),
        );
      }
    });
  }

  Widget _pageForInit() {
    return Scaffold(appBar: _appBar());
  }

  // void _onAddSubtitle(WidgetRef ref) async {
  //   // await ref.read(playerProvider(_scrollController).notifier).addSubtitle();
  // }

  Widget _pageForData(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _appBar(),
      body: Column(children: [_mediaWidget(context), _subtitleWidget(context)]),
      floatingActionButton: _floatingButtons(),
    );
  }

  Widget _mediaWidget(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: [_displayer(), _controlBar(context)]),
    );
  }

  Widget _displayer() {
    return Builder(
      builder: (context) {
        final mediaType = context.select<MobilePlayerBloc, AssetType>(
          (bloc) => bloc.state.as<MobilePlayerDataState>()?.mediaType ?? .video,
        );
        if (mediaType == .video) {
          return _videoDisplayer(context);
        } else {
          return _audioDisplayer(context);
        }
      },
    );
  }

  Widget _videoDisplayer(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        alignment: .center,
        children: [
          Builder(
            builder: (context) {
              final aspectRatio = context.select<MobilePlayerBloc, double>(
                (bloc) =>
                    bloc.state.as<MobilePlayerDataState>()?.aspectRatio ??
                    16 / 9,
              );
              return AspectRatio(aspectRatio: aspectRatio, child: _player());
            },
          ),
          _gradientDisplayerOverlay(),
          Row(
            mainAxisAlignment: .center,
            crossAxisAlignment: .end,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: .end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: _progressSlider(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 8),
                child: _verticalVolumeWidgets(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _player() {
    return Builder(
      builder: (context) {
        final player = context.select<MobilePlayerBloc, VideoPlayerController?>(
          (bloc) => bloc.state.as<MobilePlayerDataState>()?.player,
        );
        if (player == null) return const SizedBox.shrink();
        return VideoPlayer(player);
      },
    );
  }

  Widget _audioDisplayer(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
        children: [
          _player(),
          _gradientDisplayerOverlay(),
          Column(
            mainAxisSize: .max,
            mainAxisAlignment: .start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                child: _horizontalVolumeWidgets(),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: _progressSlider(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gradientDisplayerOverlay() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.4),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withValues(alpha: 0.6),
            ],
            stops: const [0.0, 0.2, 0.7, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _subtitleWidget(BuildContext context) {
    return Expanded(
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: const MobileSubtitleUI(),
      ),
    );
  }

  Widget? _floatingButtons() {
    return Builder(
      builder: (context) {
        final hasSubtitle = context.select<MobilePlayerBloc, bool>(
          (bloc) =>
              bloc.state.as<MobilePlayerDataState>()?.subtitleState
                  is SubtitleDataState,
        );
        if (!hasSubtitle) return const SizedBox.shrink();
        final colorScheme = Theme.of(context).colorScheme;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              heroTag: 'scroll_top',
              onPressed: () {
                context.read<MobilePlayerBloc>().add(
                  const MobilePlayerScrollToTopEvent(),
                );
              },
              backgroundColor: colorScheme.surfaceContainerHighest,
              foregroundColor: colorScheme.primary,
              child: const Icon(Icons.keyboard_arrow_up_rounded),
            ),
            const SizedBox(height: 8),
            FloatingActionButton.small(
              heroTag: 'scroll_focus',
              onPressed: () {
                context.read<MobilePlayerBloc>().add(
                  const MobilePlayerScrollToPlayingSentenceEvent(),
                );
              },
              child: const Icon(Icons.center_focus_strong_rounded),
            ),
            const SizedBox(height: 8),
            FloatingActionButton.small(
              heroTag: 'scroll_bottom',
              onPressed: () {
                context.read<MobilePlayerBloc>().add(
                  const MobilePlayerScrollToBottomEvent(),
                );
              },
              backgroundColor: colorScheme.surfaceContainerHighest,
              foregroundColor: colorScheme.primary,
              child: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
          ],
        );
      },
    );
  }

  Widget _verticalVolumeWidgets() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Builder(
          builder: (context) {
            final bool showVolumeSlider = context.select<MobilePlayerBloc, bool>(
              (bloc) =>
                  bloc.state.as<MobilePlayerDataState>()?.volumeSliderVisible ??
                  false,
            );
            if (showVolumeSlider) {
              return Expanded(child: _verticalVolumeSlider(context));
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
        _volumeButton(),
      ],
    );
  }

  Widget _horizontalVolumeWidgets() {
    return Row(
      mainAxisAlignment: .start,
      children: [
        _volumeButton(),
        Builder(
          builder: (context) {
            final bool showVolumeSlider = context.select<MobilePlayerBloc, bool>(
              (bloc) =>
                  bloc.state.as<MobilePlayerDataState>()?.volumeSliderVisible ??
                  false,
            );
            if (showVolumeSlider) {
              return Expanded(child: _horizontalVolumeSlider(context));
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
      ],
    );
  }

  Widget _volumeButton() {
    return Builder(
      builder: (context) {
        final volume = context.select<MobilePlayerBloc, double>(
          (bloc) => bloc.state.as<MobilePlayerDataState>()?.volume ?? 1,
        );
        final icon = volume == 0
            ? Icons.volume_off_rounded
            : Icons.volume_up_rounded;
        return IconButton(
          onPressed: () {
            context.read<MobilePlayerBloc>().add(
              const MobilePlayerToggleVolumeEvent(),
            );
          },
          icon: Icon(icon),
          color: Colors.white,
          iconSize: 32,
        );
      },
    );
  }

  Widget _verticalVolumeSlider(BuildContext context) {
    return RotatedBox(quarterTurns: 3, child: _horizontalVolumeSlider(context));
  }

  Widget _horizontalVolumeSlider(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3.0,
        // thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: Colors.white24,
        thumbColor: Colors.white,
        // padding: EdgeInsets.zero,
        thumbSize: WidgetStateProperty.all(const Size(20, 20)),
      ),
      child: Builder(
        builder: (context) {
          const double maxVolume = 1;
          final volume = context.select<MobilePlayerBloc, double>(
            (bloc) =>
                bloc.state.as<MobilePlayerDataState>()?.volume ?? maxVolume,
          );
          return Slider(
            value: volume,
            max: maxVolume,
            onChanged: (volume) {
              context.read<MobilePlayerBloc>().add(
                MobilePlayerVolumeChangeEvent(volume),
              );
            },
          );
        },
      ),
    );
  }

  Widget _progressSlider(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3.0,
        // thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: Colors.white24,
        thumbColor: Colors.white,
        // padding: EdgeInsets.zero,
        thumbSize: WidgetStateProperty.all(const Size(20, 20)),
      ),
      child: Builder(
        builder: (context) {
          final (
            position,
            duration,
          ) = context.select<MobilePlayerBloc, (Duration, Duration)>(
            (bloc) => (
              bloc.state.as<MobilePlayerDataState>()?.position ?? Duration.zero,
              bloc.state.as<MobilePlayerDataState>()?.duration ?? Duration.zero,
            ),
          );
          final max = duration.inMilliseconds.toDouble();
          final val = position.inMilliseconds.clamp(0, max).toDouble();
          return Slider(
            allowedInteraction: .slideThumb,
            value: val,
            max: max,
            onChangeStart: (val) {
              context.read<MobilePlayerBloc>().add(
                MobilePlayerMediaSliderStartChangeEvent(
                  Duration(milliseconds: val.toInt()),
                  duration,
                ),
              );
            },
            onChanged: (val) {
              context.read<MobilePlayerBloc>().add(
                MobilePlayerMediaSliderChangingEvent(
                  Duration(milliseconds: val.toInt()),
                  duration,
                ),
              );
            },
            onChangeEnd: (val) {
              context.read<MobilePlayerBloc>().add(
                MobilePlayerMediaSliderEndChangeEvent(
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

  Widget _pageForEmpty(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 80,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Ready to Shadow?',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Shadowing is the key to mastering a new language. Select a media from your albums to begin your practice session.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Your progress starts here.',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary.withValues(alpha: 0.7),
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  context.read<MobilePlayerBloc>().add(
                    MobilePlayerGoToAlbumListEvent(context),
                  );
                },
                icon: const Icon(Icons.library_music_rounded),
                label: const Text('Go to Albums'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _appBar() {
    return AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: _title(),
    );
  }

  Widget _title() {
    return SizedBox(
      height: 24,
      child: Builder(
        builder: (context) {
          final title = context.select<MobilePlayerBloc, String>(
            (bloc) => bloc.state.as<MobilePlayerDataState>()?.title ?? '',
          );
          if (title.isEmpty) {
            return const Text('');
          } else {
            return Marquee(
              text: title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              scrollAxis: Axis.horizontal,
              blankSpace: 50,
              velocity: 30,
            );
          }
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
              .select<MobilePlayerBloc, bool>(
                (bloc) =>
                    bloc.state
                        .as<MobilePlayerDataState>()
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
        final playing = context.select<MobilePlayerBloc, bool>(
          (bloc) => bloc.state.as<MobilePlayerDataState>()?.playing ?? false,
        );
        return IconButton.filled(
          onPressed: () {
            if (playing) {
              context.read<MobilePlayerBloc>().add(
                const MobilePlayerPauseEvent(),
              );
            } else {
              context.read<MobilePlayerBloc>().add(const MobilePlayerPlayEvent());
            }
          },
          icon: Icon(
            playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 24,
          ),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            tapTargetSize: .shrinkWrap,
          ),
          constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          padding: EdgeInsets.zero,
        );
      },
    );
  }

  Widget _loopButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Builder(
      builder: (context) {
        final hasSubtitle = context.select<MobilePlayerBloc, bool>(
          (bloc) =>
              bloc.state.as<MobilePlayerDataState>()?.subtitleState
                  is SubtitleDataState,
        );
        if (!hasSubtitle) return const SizedBox.shrink();
        final loop = context.select<MobilePlayerBloc, bool>(
          (bloc) => bloc.state.as<MobilePlayerDataState>()?.loopIndex != null,
        );
        return IconButton(
          onPressed: () {
            context.read<MobilePlayerBloc>().add(
              const MobilePlayerToggleLoopEvent(),
            );
          },
          icon: Icon(
            loop ? Icons.repeat_one_rounded : Icons.repeat_rounded,
            color: loop ? colorScheme.primary : colorScheme.outline,
          ),
          style: IconButton.styleFrom(tapTargetSize: .shrinkWrap),
          constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          padding: EdgeInsets.zero,
        );
      },
    );
  }

  Widget _subtitleListButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: () {
        context.read<MobilePlayerBloc>().add(
          const MobilePlayerShowSubtitleListEvent(),
        );
      },
      icon: Icon(Icons.subtitles_rounded, color: colorScheme.outline),
      style: IconButton.styleFrom(tapTargetSize: .shrinkWrap),
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
      padding: EdgeInsets.zero,
    );
  }

  Widget _speedDownButton() {
    return Builder(
      builder: (context) => IconButton(
        onPressed: () {
          context.read<MobilePlayerBloc>().add(const MobilePlayerDecSpeedEvent());
        },
        icon: const Icon(Icons.remove_circle_outline_rounded),
        color: Theme.of(context).colorScheme.outline,
        style: IconButton.styleFrom(tapTargetSize: .shrinkWrap),
        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _speedUpButton() {
    return Builder(
      builder: (context) => IconButton(
        onPressed: () {
          context.read<MobilePlayerBloc>().add(const MobilePlayerIncSpeedEvent());
        },
        icon: const Icon(Icons.add_circle_outline_rounded),
        color: Theme.of(context).colorScheme.outline,
        style: IconButton.styleFrom(tapTargetSize: .shrinkWrap),
        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _speedLabel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Builder(
      builder: (context) {
        final speed = context.select<MobilePlayerBloc, double>(
          (bloc) => bloc.state.as<MobilePlayerDataState>()?.speed ?? 1,
        );
        return GestureDetector(
          onTap: () => context.read<MobilePlayerBloc>().add(
            const MobilePlayerResetSpeedEvent(),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${speed}x',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        );
      },
    );
  }
}
