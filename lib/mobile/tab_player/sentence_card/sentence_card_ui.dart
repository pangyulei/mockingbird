import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockingbird/mobile/tab_player/sentence_card/sentence_card_bloc.dart';
import 'package:mockingbird/mobile/tab_player/sentence_card/sentence_card_event.dart';
import 'package:mockingbird/tool/extensions.dart';

class SentenceCardUI extends StatelessWidget {
  final SentenceCardBloc _bloc;
  const SentenceCardUI(this._bloc, {super.key});

  @override
  Widget build(BuildContext context) {
    const double radius = 8;
    return BlocProvider.value(
      value: _bloc,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(1, 4, 8, 4),
        child: Builder(
          builder: (context) {
            final playing = context.select<SentenceCardBloc, bool>(
              (bloc) => bloc.state.playing,
            );
            final borderRadius = BorderRadius.only(
              topLeft: const Radius.circular(radius),
              topRight: const Radius.circular(radius),
              bottomRight: const Radius.circular(radius),
              bottomLeft: Radius.circular(playing ? 4 : radius),
            );
            return GestureDetector(
              onTap: () => context.read<SentenceCardBloc>().add(
                SentenceCardClickEvent(context),
              ),
              child: ClipRRect(
                borderRadius: borderRadius,
                child: BackdropFilter(
                  filter: kGlassFilter,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      image: kGlassDecorationImage,
                      gradient: kGlassGradient,
                      borderRadius: borderRadius,
                      // boxShadow: playing
                      //     ? [
                      //         BoxShadow(
                      //           color: colorScheme.primary.withValues(alpha: 0.2),
                      //           blurRadius: 8,
                      //           offset: const Offset(0, 2),
                      //         ),
                      //       ]
                      //     : null,
                      border: Border.all(color: kGlassBorderColor, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(
                            builder: (context) {
                              final content = context
                                  .select<SentenceCardBloc, String>(
                                    (bloc) => bloc.state.text,
                                  );
                              return Text(
                                content,
                                style: kTextStyle(
                                  size: 20,
                                  color: playing
                                      ? kPrimaryTextColor
                                      : kSecondaryTextColor,
                                  weight: playing ? .bold : .normal,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Builder(
                                builder: (context) {
                                  final (period, playing) = context
                                      .select<SentenceCardBloc, (String, bool)>(
                                        (bloc) => (
                                          bloc.state.period,
                                          bloc.state.playing,
                                        ),
                                      );
                                  return Text(
                                    period,
                                    style: kTextStyle(
                                      size: 12,
                                      color: playing
                                          ? kPrimaryTextColor
                                          : kSecondaryTextColor,
                                      weight: .normal,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
