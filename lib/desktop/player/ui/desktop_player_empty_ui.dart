import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
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
      child: Scaffold(
        body: DropTarget(
          onDragDone: (details) {
            final path = details.files.firstOrNull?.path;
            if (path != null) {
              context.read<DesktopPlayerBloc>().add(
                DesktopPlayerDropMediaEvent(File(path)),
              );
            }
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: ImageContainer(
              image:Image.asset('assets/desktop/main_window_background.jpg').image,
              padding: const EdgeInsets.all(8),
              child: Builder(
                builder: (context) {
                  return GestureDetector(
                    onTap: () => context.read<DesktopPlayerBloc>().add(
                      const DesktopPlayerPickMediaFromFileExplorerEvent(),
                    ),
                    child: GlassContainer(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: kPrimaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.cloud_upload_outlined,
                                size: 48,
                                color: kPrimaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Drag & Drop Media File Here',
                              style: kTextStyle(
                                size: 24,
                                color: kPrimaryTextColor,
                                weight: .bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'or click anywhere in this area to browse your video/audio files',
                              style: kTextStyle(
                                size: 16,
                                color: kSecondaryTextColor,
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
        ),
      ),
    );
  }
}
