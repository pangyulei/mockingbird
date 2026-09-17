import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockingbird/mobile/tab_player/subtitle_list/mobile_subtitle_list_event.dart';
import 'package:mockingbird/mobile/tab_player/subtitle_list/mobile_subtitle_list_state.dart';

abstract class MobileSubtitleListBlocType
    extends Bloc<MobileSubtitleListEvent, MobileSubtitleListState> {
  MobileSubtitleListBlocType(super.initialState);
}

class MobileSubtitleListUI extends StatelessWidget {
  final MobileSubtitleListBlocType _bloc;

  const MobileSubtitleListUI(this._bloc, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return BlocProvider.value(
      value: _bloc,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                'Select Subtitle',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            Flexible(
              child: Builder(
                builder: (context) {
                  final state = context.watch<MobileSubtitleListBlocType>().state;
                  final subtitleList = state.subtitleList;
                  final selectedName = state.selectedSubtitleName;
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: subtitleList.length,
                    itemBuilder: (context, index) {
                      final subtitle = subtitleList[index];
                      final isSelected = subtitle.name == selectedName;

                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: Icon(
                            Icons.subtitles_rounded,
                            color: isSelected ? colorScheme.primary : colorScheme.outline,
                          ),
                          title: Text(
                            subtitle.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
                              : null,
                          onTap: () {
                            context.read<MobileSubtitleListBlocType>().add(
                              MobileSubtitleListSelectNameEvent(subtitle.name, context),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
