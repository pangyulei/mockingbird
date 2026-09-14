
import 'dart:io';

import 'package:defer/defer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockingbird/desktop/player/desktop_player_event.dart';
import 'package:mockingbird/desktop/player/desktop_player_state.dart';

import '../../tool/extensions.dart';

class DesktopPlayerBloc extends Bloc<DesktopPlayerEvent, DesktopPlayerState> {
  DesktopPlayerBloc() : super(const DesktopPlayerEmptyState()) {
    on<DesktopPlayerSelectMediaFromFileExplorerEvent>(_selectMediaFromFileExplorer);
  }

  void _selectMediaFromFileExplorer(DesktopPlayerSelectMediaFromFileExplorerEvent event, Emitter<DesktopPlayerState> emit) async {
    await defer(()async{},() async{});
    final xfile = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: [
        ...kVideoExtensions,
        ...kAudioExtensions
      ],
    );
    final filePath = xfile?.path;
    if (filePath == null) return;
    final mediaFile = File(filePath);

  }

  // Future<void> _handleFileSelection(
  //   BuildContext context,
  //   String filePath,
  // ) async {
  //   try {
  //     EasyLoading.show(status: 'Loading media file...');
  //     final fileName = filePath.split(Platform.pathSeparator).last;

  //     final assetPaths = await PhotoManager.getAssetPathList(
  //       type: RequestType.video | RequestType.audio,
  //     );

  //     AssetEntity? matchedAsset;
  //     for (final path in assetPaths) {
  //       final assetCount = await path.assetCountAsync;
  //       final assets = await path.getAssetListRange(start: 0, end: assetCount);
  //       for (final asset in assets) {
  //         final file = await asset.file;
  //         if (file?.path == filePath ||
  //             asset.title?.toLowerCase() == fileName.toLowerCase()) {
  //           matchedAsset = asset;
  //           break;
  //         }
  //       }
  //       if (matchedAsset != null) break;
  //     }

  //     if (matchedAsset == null) {
  //       final lowercasePath = filePath.toLowerCase();
  //       if (lowercasePath.endsWith('.mp4') ||
  //           lowercasePath.endsWith('.mov') ||
  //           lowercasePath.endsWith('.avi') ||
  //           lowercasePath.endsWith('.mkv')) {
  //         matchedAsset = await PhotoManager.editor.saveVideo(
  //           File(filePath),
  //           title: fileName,
  //         );
  //       } else {
  //         matchedAsset = await PhotoManager.editor.saveImageWithPath(
  //           filePath,
  //           title: fileName,
  //         );
  //       }
  //     }

  //     if (context.mounted) {
  //       context.read<DesktopPlayerBloc>().add(
  //         PlayerInitEvent(mediaId: matchedAsset.id),
  //       );
  //     }
  //   } catch (e) {
  //     debugPrint('Error handling file selection: $e');
  //     EasyLoading.showError('Failed to load file into player.');
  //   } finally {
  //     EasyLoading.dismiss();
  //   }
  // }
}