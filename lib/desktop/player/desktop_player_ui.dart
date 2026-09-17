import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:file_picker/file_picker.dart';
import 'package:marquee/marquee.dart';
import 'package:mockingbird/desktop/player/desktop_player_bloc.dart';
import 'package:mockingbird/desktop/player/desktop_player_event.dart';
import 'package:mockingbird/desktop/player/desktop_player_state.dart';
import 'package:mockingbird/mobile/tab_player/player/mobile_player_state.dart';
import 'package:mockingbird/mobile/tab_player/subtitle_list/mobile_subtitle_list_bloc.dart';
import 'package:mockingbird/mobile/tab_player/subtitle_list/mobile_subtitle_list_ui.dart';
import 'package:mockingbird/mobile/tab_player/sentence_card/sentence_card_ui.dart';
import 'package:mockingbird/mobile/tab_settings/about/about_ui.dart';
import 'package:mockingbird/tool/extensions.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:video_player/video_player.dart';

enum DesktopLayoutMode { stacked, snappedSide, detached }

class DesktopPlayerUI extends StatelessWidget {
  const DesktopPlayerUI({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('desktop player ui building');
    return BlocProvider(
      create: (context) => DesktopPlayerBloc(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: BlocListener<DesktopPlayerBloc, DesktopPlayerState>(
          listenWhen: (previous, current) {
            return (previous is! DesktopPlayerDataState || previous.subtitleListVisible == false) && current is DesktopPlayerDataState && current.subtitleListVisible;
          },
          listener: (context, state) => _showSubtitleList(context),
          child: Builder(
            builder: (context) {
              final stateType = context.select<DesktopPlayerBloc, Type>(
                (bloc) => bloc.state.runtimeType,
              );
              switch (stateType) {
                case DesktopPlayerEmptyState:
                  return _pageForEmpty();
                case DesktopPlayerDataState:
                  return _pageForData(context);
                default:
                  assert(false, 'stateType $stateType missed');
                  return const SizedBox.shrink();
              }
            },
          ),
        ),
      ),
    );
  }

  void _showSubtitleList(BuildContext context) {
    final state = context
        .read<DesktopPlayerBloc>().state.as<DesktopPlayerDataState>();
    if (state == null) return;
    final bloc = MobileSubtitleListBloc(state.subtitleList, state.subtitleState.as<PlayerSubtitleDataState>()?.subtitleName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return MobileSubtitleListUI(bloc);
      },
    ).whenComplete(() {
      if (context.mounted) {
        context.read<DesktopPlayerBloc>().add(
          const DesktopPlayerHideSubtitleListEvent(),
        );
      }
    });
  }

  Widget _pageForData(BuildContext context) {
    return _mediaWidget(context);
  }

  Widget _mediaWidget(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.black),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _appBar(context),
          Expanded(child: Center(child: _displayer())),
          _controlBar(context),
        ],
      ),
    );
  }

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

  Widget _displayer() {
    return Builder(
      builder: (context) {
        final mediaType = context.select<DesktopPlayerBloc, AssetType>(
          (bloc) =>
              bloc.state.as<DesktopPlayerDataState>()?.mediaType ?? AssetType.video,
        );
        if (mediaType == AssetType.video) {
          return _videoDisplayer(context);
        } else {
          return _audioDisplayer(context);
        }
      },
    );
  }

  Widget _videoDisplayer(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Builder(
          builder: (context) {
            final aspectRatio = context.select<DesktopPlayerBloc, double>(
              (bloc) => bloc.state.as<DesktopPlayerDataState>()?.aspectRatio ?? 16 / 9,
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

  Widget _audioDisplayer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.audiotrack_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          _volumeWidgets(context),
          const SizedBox(height: 16),
          _progressSlider(context),
        ],
      ),
    );
  }

  Widget _volumeWidgets(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _volumeButton(),
        Expanded(child: _volumeSlider(context)),
      ],
    );
  }

  Widget _volumeButton() {
    return Builder(
      builder: (context) {
        final volume = context.select<DesktopPlayerBloc, double>(
          (bloc) => bloc.state.as<DesktopPlayerDataState>()?.volume ?? 1,
        );
        final icon = volume == 0
            ? Icons.volume_off_rounded
            : Icons.volume_up_rounded;
        return IconButton(
          onPressed: () {
            context.read<DesktopPlayerBloc>().add(
              const DesktopPlayerToggleMuteEvent(),
            );
          },
          icon: Icon(icon),
          color: Colors.white,
          iconSize: 24,
        );
      },
    );
  }

  Widget _volumeSlider(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3.0,
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: Colors.white24,
        thumbColor: Colors.white,
        thumbSize: WidgetStateProperty.all(const Size(12, 12)),
      ),
      child: Builder(
        builder: (context) {
          const double maxVolume = 1;
          final volume = context.select<DesktopPlayerBloc, double>(
            (bloc) => bloc.state.as<DesktopPlayerDataState>()?.volume ?? maxVolume,
          );
          return Slider(
            value: volume,
            max: maxVolume,
            onChanged: (volume) {
              context.read<DesktopPlayerBloc>().add(
                DesktopPlayerVolumeChangeEvent(volume),
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
                  bloc.state.as<DesktopPlayerDataState>()?.position ?? Duration.zero,
                  bloc.state.as<DesktopPlayerDataState>()?.duration ?? Duration.zero,
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
              context.read<DesktopPlayerBloc>().add(const DesktopPlayerPauseEvent());
            } else {
              context.read<DesktopPlayerBloc>().add(const DesktopPlayerPlayEvent());
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
                  is PlayerSubtitleDataState,
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
    final state = context.watch<DesktopPlayerBloc>().state.as<DesktopPlayerDataState>();
    if (state == null) return const SizedBox.shrink();
    
    final currentSubtitleName = state.subtitleState.as<PlayerSubtitleDataState>()?.subtitleName;

    return MenuAnchor(
      builder: (context, controller, child) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: Icon(Icons.subtitles_rounded, color: colorScheme.outline, size: 20),
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
          tooltip: 'Select Subtitle',
        );
      },
      menuChildren: state.subtitleList.map((subtitle) {
        final isSelected = subtitle.name == currentSubtitleName;
        return MenuItemButton(
          leadingIcon: Icon(
            isSelected ? Icons.check_circle_rounded : Icons.subtitles_rounded,
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            size: 18,
          ),
          child: Text(
            subtitle.name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
          onPressed: () {
            context.read<DesktopPlayerBloc>().add(DesktopPlayerSelectSubtitleEvent(subtitle.name));
          },
        );
      }).toList(),
    );
  }

  Widget _speedDownButton() {
    return Builder(
      builder: (context) => IconButton(
        onPressed: () {
          context.read<DesktopPlayerBloc>().add(const DesktopPlayerDecSpeedEvent());
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
          context.read<DesktopPlayerBloc>().add(const DesktopPlayerIncSpeedEvent());
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


  Widget _pageForEmpty() {
    return Center(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Builder(
          builder: (context) {
            final colorScheme = Theme.of(context).colorScheme;
            final textTheme = Theme.of(context).textTheme;
            return GestureDetector(
              onTap: () {
                context.read<DesktopPlayerBloc>().add(const DesktopPlayerSelectMediaFromFileExplorerEvent());
              },
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.4),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        size: 48,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Drag & Drop Media File Here',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'or click anywhere in this area to browse your video/audio files',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
        ),
      ),
    );
  }
}