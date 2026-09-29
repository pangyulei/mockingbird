import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockingbird/db/entities/subtitle.dart';
import 'package:mockingbird/desktop/player/desktop_player_bloc.dart';
import 'package:mockingbird/desktop/player/desktop_player_event.dart';
import 'package:mockingbird/mobile/tab_player/sentence_card/sentence_card_ui.dart';
import 'package:mockingbird/tool/comm_player/comm_player_event.dart';
import 'package:mockingbird/tool/comm_player/comm_player_state.dart';
import 'package:mockingbird/tool/extensions.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:video_player/video_player.dart';

import '../../../mobile/tab_player/subtitle/subtitle_state.dart';
import '../desktop_player_state.dart';

const double kDesktopPlayerLeftWidth = 600;
const double kDesktopPlayerRightWidth = 300;
const double kDesktopPlayerDividerThickness = 6; // 稍微加粗一点，方便鼠标抓取
const double kDesktopPlayerEmptyHeight = 400;
const double kDesktopPlayerDataHeight = 450;

class DesktopPlayerVideoUI extends StatelessWidget {
  const DesktopPlayerVideoUI({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: DesktopPlayerBloc.shared,
      child: Scaffold(
        body: imageContainer(
          Image.asset('assets/desktop/main_window_background.jpg').image,
          child: MultiSplitViewTheme(
            data: MultiSplitViewThemeData(
              dividerThickness: kDesktopPlayerDividerThickness,
              dividerPainter: DividerPainters.grooved1(
                color: kPrimaryColor,
                highlightedColor: kPrimaryColor,
                thickness: 4,
              ),
            ),
            child: Builder(
              builder: (context) {
                final splitter = context.select<DesktopPlayerBloc, MultiSplitViewController>(
                  (bloc) => (bloc.state as DesktopPlayerDataState).splitter,
                );
                return MultiSplitView(controller: splitter, axis: Axis.horizontal);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class DesktopPlayerVideoLeftUI extends StatelessWidget {
  const DesktopPlayerVideoLeftUI({super.key});

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (details) {
        final path = details.files.firstOrNull?.path;
        if (path != null) {
          context.read<DesktopPlayerBloc>().add(DesktopPlayerDropMediaEvent(File(path)));
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 2, 8),
        child: Column(
          mainAxisAlignment: .center,
          mainAxisSize: .min,
          children: [
            Flexible(
              child: glassContainer(padding: const EdgeInsets.all(8), child: _videoDisplayer()),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: glassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                child: _controlBar(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _videoDisplayer() {
    return Column(
      mainAxisAlignment: .center,
      mainAxisSize: .min,
      children: [
        Flexible(
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Builder(
                  builder: (context) {
                    final aspectRatio = context.select<DesktopPlayerBloc, double>(
                      (bloc) => bloc.state.as<CommPlayerDataState>()?.aspectRatio ?? 16 / 9,
                    );
                    return AspectRatio(aspectRatio: aspectRatio, child: _player());
                  },
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Builder(
                  builder: (context) {
                    final text =
                        context.select<DesktopPlayerBloc, String?>(
                          (bloc) => bloc.state.as<CommPlayerDataState>()?.playingSentence?.text,
                        ) ??
                        '';
                    return Text(
                      text,
                      textAlign: .center,
                      style: kTextStyle(
                        size: 14,
                        color: kPrimaryTextColor,
                        weight: .bold,
                        backgroundColor: Colors.black.withValues(alpha: 0.5),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        _progressSlider(),
      ],
    );
  }

  Widget _player() {
    return Builder(
      builder: (context) {
        final player = context.select<DesktopPlayerBloc, VideoPlayerController?>(
          (bloc) => bloc.state.as<CommPlayerDataState>()?.player,
        );
        if (player == null) return const SizedBox.shrink();
        return VideoPlayer(player);
      },
    );
  }

  Widget _progressSlider() {
    return SliderTheme(
      data: const SliderThemeData(
        trackHeight: 3.0,
        activeTrackColor: kPrimaryColor,
        inactiveTrackColor: kPrimaryTextColor,
        thumbColor: kPrimaryColor,
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

  Widget _controlBar() {
    return Builder(
      builder: (context) {
        final (subtitleListButtonVisible, sentenceButtonVisible) = context.select<DesktopPlayerBloc, (bool, bool)>((
          bloc,
        ) {
          final data = bloc.state.as<CommPlayerDataState>();
          return (data?.subtitleListButtonVisible ?? false, data?.sentenceButtonVisible ?? false);
        });
        return Row(
          children: [
            _playOrPauseButton(context),
            if (sentenceButtonVisible) ...[
              const SizedBox(width: 16),
              _loopButton(context),
              const SizedBox(width: 8),
              _prevSentenceButton(context),
              const SizedBox(width: 8),
              _nextSentenceButton(context),
            ],
            if (subtitleListButtonVisible) ...[const SizedBox(width: 16), _subtitleListButton(context)],
            const Spacer(),
            _speedDownButton(),
            const SizedBox(width: 8),
            _speedLabel(context),
            const SizedBox(width: 8),
            _speedUpButton(),
          ],
        );
      },
    );
  }

  Widget _playOrPauseButton(BuildContext context) {
    return Builder(
      builder: (context) {
        final playing = context.select<DesktopPlayerBloc, bool>(
          (bloc) => bloc.state.as<CommPlayerDataState>()?.playing ?? false,
        );
        return IconButton.filled(
          onPressed: () {
            if (playing) {
              context.read<DesktopPlayerBloc>().add(const CommPlayerPauseEvent());
            } else {
              context.read<DesktopPlayerBloc>().add(const CommPlayerPlayEvent());
            }
          },
          icon: Icon(playing ? Icons.pause : Icons.play_arrow, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: kPrimaryTextColor,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          padding: EdgeInsets.zero,
        );
      },
    );
  }

  Widget _loopButton(BuildContext context) {
    return Builder(
      builder: (context) {
        final hasSubtitle = context.select<DesktopPlayerBloc, bool>(
          (bloc) => bloc.state.as<CommPlayerDataState>()?.subtitleState is SubtitleDataState,
        );
        if (!hasSubtitle) return const SizedBox.shrink();
        final loop = context.select<DesktopPlayerBloc, bool>(
          (bloc) => bloc.state.as<CommPlayerDataState>()?.loopIndex != null,
        );
        return IconButton(
          onPressed: () {
            context.read<DesktopPlayerBloc>().add(const CommPlayerToggleLoopEvent());
          },
          icon: Icon(loop ? Icons.repeat_one : Icons.repeat, color: loop ? kPrimaryColor : kPrimaryTextColor, size: 32),
          style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
        );
      },
    );
  }

  Widget _prevSentenceButton(BuildContext context) {
    return IconButton(
      onPressed: () {
        context.read<DesktopPlayerBloc>().add(const CommPlayerPlayPreviousSentenceEvent());
      },
      icon: const Icon(Icons.skip_previous, color: kPrimaryColor, size: 36),
      style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
    );
  }

  Widget _nextSentenceButton(BuildContext context) {
    return IconButton(
      onPressed: () {
        context.read<DesktopPlayerBloc>().add(const CommPlayerPlayNextSentenceEvent());
      },
      icon: const Icon(Icons.skip_next, color: kPrimaryColor, size: 36),
      style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
    );
  }

  Widget _subtitleListButton(BuildContext context) {
    return IconButton(
      onPressed: () {
        context.read<DesktopPlayerBloc>().add(const CommPlayerShowSubtitleListEvent());
      },
      icon: const Icon(Icons.subtitles, color: kPrimaryColor, size: 32),
      style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
    );
  }

  Widget _speedUpButton() {
    return Builder(
      builder: (context) => IconButton(
        onPressed: () {
          context.read<DesktopPlayerBloc>().add(const CommPlayerIncSpeedEvent());
        },
        icon: const Icon(Icons.add_circle_outline, size: 32),
        color: kPrimaryColor,
        style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _speedDownButton() {
    return Builder(
      builder: (context) => IconButton(
        onPressed: () {
          context.read<DesktopPlayerBloc>().add(const CommPlayerDecSpeedEvent());
        },
        icon: const Icon(Icons.remove_circle_outline, size: 32),
        color: kPrimaryColor,
        style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _speedLabel(BuildContext context) {
    return Builder(
      builder: (context) {
        final speed = context.select<DesktopPlayerBloc, double>(
          (bloc) => bloc.state.as<CommPlayerDataState>()?.speed ?? 1,
        );
        return GestureDetector(
          onTap: () => context.read<DesktopPlayerBloc>().add(const CommPlayerResetSpeedEvent()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: kPrimaryColor, borderRadius: BorderRadius.circular(6)),
            child: Text(
              '${speed}x',
              style: const TextStyle(color: kPrimaryTextColor, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        );
      },
    );
  }

  // Widget _appBar(BuildContext context) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //     color: Colors.black.withValues(alpha: 0.6),
  //     child: Row(
  //       children: [
  //         Expanded(
  //           child: Builder(
  //             builder: (context) {
  //               final title = context.select<DesktopPlayerBloc, String>(
  //                 (bloc) => bloc.state.as<CommPlayerDataState>()?.title ?? '',
  //               );
  //               return SizedBox(
  //                 height: 24,
  //                 child: title.isEmpty
  //                     ? const Text('')
  //                     : Marquee(
  //                         text: title,
  //                         style: const TextStyle(
  //                           fontSize: 14,
  //                           fontWeight: FontWeight.bold,
  //                           color: Colors.white,
  //                         ),
  //                         scrollAxis: Axis.horizontal,
  //                         blankSpace: 50,
  //                         velocity: 30,
  //                       ),
  //               );
  //             },
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  //
}

class DesktopPlayerVideoRightUI extends StatelessWidget {
  const DesktopPlayerVideoRightUI({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: DesktopPlayerBloc.shared,
      child: BlocListener<DesktopPlayerBloc, CommPlayerState>(
        listenWhen: (previous, current) =>
            (previous is! CommPlayerDataState || !previous.subtitleListVisible) &&
            (current is CommPlayerDataState && current.subtitleListVisible),
        listener: (context, state) => _showSubtitleList(context),
        child: Builder(
          builder: (context) {
            final subtitleState = context.select<DesktopPlayerBloc, SubtitleState?>(
              (bloc) => bloc.state.as<CommPlayerDataState>()?.subtitleState,
            );
            switch (subtitleState) {
              case null || SubtitleEmptyState():
                return _noSubtitleWidget(context);
              case SubtitleDataState data:
                return _subtitleWidget(data);
            }
          },
        ),
      ),
    );
  }

  Widget _subtitleWidget(SubtitleDataState data) {
    return Builder(
      builder: (context) {
        return DropTarget(
          onDragDone: (details) {
            final path = details.files.firstOrNull?.path;
            if (path != null) {
              context.read<DesktopPlayerBloc>().add(DesktopPlayerDropSubtitleEvent(File(path)));
            }
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
            child: ScrollablePositionedList.builder(
              key: ValueKey(data),
              itemCount: data.subtitle.sentenceList.length,
              itemScrollController: data.scroller,
              initialAlignment: data.initialAlignment,
              initialScrollIndex: data.initialIndex,
              itemBuilder: (context, i) {
                final sentenceCardBloc = context.read<DesktopPlayerBloc>().sentenceCardBlocAtIndex(i);
                return SentenceCardUI(sentenceCardBloc);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _noSubtitleWidget(BuildContext context) {
    return DropTarget(
      onDragDone: (details) {
        final path = details.files.firstOrNull?.path;
        if (path != null) {
          context.read<DesktopPlayerBloc>().add(DesktopPlayerDropSubtitleEvent(File(path)));
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            context.read<DesktopPlayerBloc>().add(const DesktopPlayerPickSubtitleFromFileExplorerEvent());
          },
          child: glassContainer(
            margin: const EdgeInsets.fromLTRB(1, 8, 8, 8),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(color: kPrimaryColor, shape: BoxShape.circle),
                      child: const Icon(Icons.subtitles, size: 44, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Subtitles Track',
                      style: kTextStyle(color: kPrimaryTextColor, size: 16, weight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Click or Drag & Drop subtitle file here',
                      style: kTextStyle(color: kSecondaryTextColor, size: 13, weight: FontWeight.normal),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Supports .srt and .vtt formats',
                      style: kTextStyle(
                        color: kSecondaryTextColor.withValues(alpha: 0.6),
                        size: 11,
                        weight: FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSubtitleList(BuildContext context) async {
    final bloc = context.read<DesktopPlayerBloc>();
    final state = bloc.state.as<CommPlayerDataState>();
    if (state == null || state.subtitleList.isEmpty) return;

    final currentSubtitle = state.subtitle;

    final selected = await showDialog<Subtitle>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black26,
      builder: (dialogContext) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360, maxHeight: 400),
            child: Material(
              color: Colors.transparent,
              child: glassContainer(
                radius: 16,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.subtitles, color: kPrimaryColor, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Select Subtitle',
                            style: kTextStyle(size: 16, color: kPrimaryTextColor, weight: .bold),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: Icon(Icons.close, color: kSecondaryTextColor, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 16),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: state.subtitleList.length,
                          itemBuilder: (context, index) {
                            final subtitle = state.subtitleList[index];
                            final isSelected = subtitle == currentSubtitle;
                            return InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => Navigator.of(dialogContext).pop(subtitle),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected ? Icons.check_circle : Icons.subtitles_outlined,
                                      size: 18,
                                      color: isSelected ? kPrimaryColor : kSecondaryTextColor,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        subtitle.name,
                                        style: kTextStyle(
                                          size: 14,
                                          color: isSelected ? kPrimaryTextColor : kSecondaryTextColor,
                                          weight: isSelected ? .bold : .normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (!context.mounted) return;

    if (selected != null) {
      bloc.add(CommPlayerPickSubtitleFromListEvent(selected));
    } else {
      bloc.add(const CommPlayerHideSubtitleListEvent());
    }
  }
}
