import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockingbird/db/entities/subtitle.dart';
import 'package:mockingbird/desktop/player/desktop_player_bloc.dart';
import 'package:mockingbird/tool/comm_player/comm_player_event.dart';
import 'package:mockingbird/tool/comm_player/comm_player_state.dart';
import 'package:mockingbird/tool/extensions.dart';

void showSubtitleList(BuildContext context) async {
  final bloc = context.read<DesktopPlayerBloc>();
  final data = bloc.state.as<CommPlayerDataState>();
  final subtitleList = data?.subtitleList;
  final subtitle = data?.subtitle;
  if (subtitleList == null || subtitleList.isEmpty || subtitle == null) return;

  final selected = await showDialog<Subtitle>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black26,
    builder: (dialogContext) {
      return DesktopPlayerSubtitleList(
        subtitleList: subtitleList,
        selectedSubtitle: subtitle,
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

class DesktopPlayerSubtitleList extends StatelessWidget {
  final List<Subtitle> _subtitleList;
  final Subtitle _selectedSubtitle;
  const DesktopPlayerSubtitleList({
    required this._subtitleList,
    required this._selectedSubtitle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360, maxHeight: 400),
        child: Material(
          color: Colors.transparent,
          child: GlassContainer(
            radius: 16,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.subtitles,
                        color: kPrimaryColor,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Select Subtitle',
                        style: kTextStyle(
                          size: 16,
                          color: kPrimaryTextColor,
                          weight: .bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        // onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: Icon(
                          Icons.close,
                          color: kSecondaryTextColor,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 16),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _subtitleList.length,
                      itemBuilder: (context, index) {
                        final subtitle = _subtitleList[index];
                        final isSelected = subtitle == _selectedSubtitle;
                        return InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => Navigator.of(context).pop(subtitle),
                          // onTap: () => Navigator.of(dialogContext).pop(subtitle),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.subtitles_outlined,
                                  size: 18,
                                  color: isSelected
                                      ? kPrimaryColor
                                      : kSecondaryTextColor,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    subtitle.name,
                                    style: kTextStyle(
                                      size: 14,
                                      color: isSelected
                                          ? kPrimaryTextColor
                                          : kSecondaryTextColor,
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
  }
}
