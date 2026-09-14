import 'dart:io';
import 'dart:math';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:mockingbird/tool/subtitle_parser.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:window_manager/window_manager.dart';

import '../db/entities/sentence.dart';
import '../db/entities/subtitle.dart';
import '../objectbox.g.dart';

extension WindowControllerHelper on WindowController {
  Future<void> bindMethods() async {
    await setWindowMethodHandler((call) async {
      switch (call.method) {
        case 'window_close':
          return await windowManager.close(); // real close, not hide
        default:
          throw Exception('Not implemented: ${call.method}');
      }
    });
  }

  Future<void> close() => invokeMethod('window_close'); // this is what you want
}

extension ObjectHelper on Object {
  T? as<T>() {
    return (this is T) ? (this as T) : null;
  }
}

extension IterableHelper<E> on Iterable<E> {
  int? firstIndexWhereOrNull(bool Function(E) test) {
    int i = 0;
    for (final element in this) {
      if (test(element)) {
        return i;
      }
      i++;
    }
    return null;
  }
}

extension ScrollHelper on ItemScrollController {
  void safeJumpTo(int? index, {double alignment = 0}) {
    if (isAttached && index != null) {
      // debugPrint('${identityHashCode(this)} will jump to index $index');
      jumpTo(index: index, alignment: alignment);
    } else {
      // debugPrint(
      //   '${identityHashCode(this)} jump fail, attached $isAttached, index $index',
      // );
    }
  }

  void safeScrollTo(
    int? index, {
    double alignment = 0,
    Duration duration = const Duration(milliseconds: 250),
  }) {
    if (isAttached && index != null) {
      // debugPrint(
      //   '${identityHashCode(this)} will scroll to index $index align $alignment',
      // );
      scrollTo(index: index, duration: duration, alignment: alignment);
    } else {
      // debugPrint(
      //   '${identityHashCode(this)} scroll fail, attached $isAttached, index $index',
      // );
    }
  }
}


const kAudioExtensions = {
  'mp3', 'm4a', 'wav', 'flac', 'aac',
  'ogg', 'oga', 'ape', 'wma', 'amr',
  'opus', 'mid', 'midi', 'aif', 'aiff',
  'aifc', 'mp4a', 'mpc', 'm4r' // m4r 是 iPhone 铃声
};

const kVideoExtensions = {'mp4', 'mkv', 'mov', 'avi', 'webm',
  'flv', 'f4v', 'ts', 'wmv', 'm4v',
  'mts', 'm2ts', 'rmvb', 'rm', 'mpg',
  'mpeg', 'mpe', '3gp', '3g2', 'vob',
  'asf', 'ogv'};

const kSubtitleExtensions = {'srt', 'vtt'};

extension AssetEntityHelper on AssetEntity {
  Future<List<Subtitle>> get subtitleList async {
    //找到同目录下的名称对应上的srt或vtt字幕文件
    final mediaFile = await file;
    return mediaFile == null ? [] : await mediaFile.subtitleList;
  }
}

extension FileHelper on File {
  Future<List<Subtitle>> get subtitleList async {
    final subtitleList = <Subtitle>[];
    await for (final anyFile in parent.list()) {
      if (anyFile is! File) continue;
      final extension = p.extension(anyFile.path).substring(1);
      if (!kSubtitleExtensions.contains(extension)) continue;
      final subtitleName = p.basenameWithoutExtension(anyFile.path);
      final mediaName = p.basenameWithoutExtension(path);
      final matched = subtitleName.toLowerCase().contains(
        mediaName.toLowerCase(),
      );
      if (matched) {
        final Subtitle = await SubtitleParser.parseFile(anyFile);
        if (Subtitle != null) {
          subtitleList.add(Subtitle);
        }
      }
    }
    return subtitleList;
  }
}

extension DurationHelper on Duration {
  String get desc {
    final h = inHours;
    final m = inMinutes.remainder(60);
    final s = inSeconds.remainder(60);
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

typedef SpotType = ({int index, SentenceEntity sentence});

extension SpotTypeHelper on SpotType {
  double get alignment => index == 0 ? 0 : 0.3;
}

extension SentenceListHelper on List<SentenceEntity> {
  SpotType? spot(Duration position) {
    for (int i = 0; i < length; i++) {
      SentenceEntity? prev = i == 0 ? null : this[i - 1];
      SentenceEntity? next = elementAtOrNull(i + 1);
      SentenceEntity sentence = this[i];
      if (sentence.playing(prev, next, position)) {
        return (index: i, sentence: sentence);
      }
    }
    return null;
  }
}

extension on SentenceEntity {
  bool playing(SentenceEntity? prev, SentenceEntity? next, Duration position) {
    final start = prev == null ? Duration.zero : this.start;
    if (next == null) {
      return start <= position;
    } else {
      return start <= position && position < next.start;
    }
  }
}

extension DoubleHelper on double {
  /// Returns a double rounded to N decimal places
  double digits(int fractionDigits) {
    num mod = pow(10, fractionDigits);
    return ((this * mod).round().toDouble() / mod);
  }
}

enum PlatformType { desktop, mobile, tablet }

PlatformType get kPlatformType {
  if (Platform.isFuchsia ||
      Platform.isLinux ||
      Platform.isWindows ||
      Platform.isMacOS) {
    return .desktop;
  }
  return .mobile; //TODO here should differ tablet version
}

Future<Store> initDB({Store? store}) async {
  if (store == null) {
    final appDir = await getApplicationDocumentsDirectory();
    // Future<Store> openStore() {...} is defined in the generated objectbox.g.dart
    store = await openStore(directory: p.join(appDir.path, "db_objectbox"));
  }
  if (kDebugMode) {
    if (Admin.isAvailable()) {
      Admin(store);
    } else {
      debugPrint('ObjectBox Admin is NOT available');
    }
  }
  return store;
}


typedef PositionUpdated = ({
  bool mediaCompleted,
  SentenceEntity? completedLoopSentence,
  bool sentenceChanged,
});