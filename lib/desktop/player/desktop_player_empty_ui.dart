import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockingbird/desktop/player/desktop_player_bloc.dart';
import 'package:mockingbird/desktop/player/desktop_player_event.dart';
import 'package:mockingbird/tool/extensions.dart';

class DesktopPlayerEmptyUI extends StatelessWidget {
  const DesktopPlayerEmptyUI({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: DesktopPlayerBloc.shared,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 1, 8),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Builder(
            builder: (context) {
              return GestureDetector(
                onTap: () => context.read<DesktopPlayerBloc>().add(
                  const DesktopPlayerSelectMediaFromFileExplorerEvent(),
                ),
                child: glassContainer(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: kPrimaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_upload_outlined,
                            size: 48,
                            color: kPrimaryWhite,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Drag & Drop Media File Here',
                          style: mbTextStyle(
                            size: 24,
                            color: kPrimaryWhite,
                            weight: .bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'or click anywhere in this area to browse your video/audio files',
                          style: mbTextStyle(
                            size: 16,
                            color: kSecondaryWhite,
                            weight: .normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
