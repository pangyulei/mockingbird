import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:mockingbird/tool/event_hub.dart';
import 'package:mockingbird/tool/extensions.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class MobileBackgroundAudioPlayer extends BaseAudioHandler {
  final _audioPlayer = AudioPlayer();
  PlayerInfo? _playerInfo;

  MobileBackgroundAudioPlayer() {
    EventHub.on<HubSyncPlayerToBackgroundAudioEvent>(_onSyncFromPlayer);
    EventHub.on<HubAppResumeEvent>(_onAppResume);
    _audioPlayer.speedStream.listen((speed) {
      playbackState.add(playbackState.value.copyWith(speed: speed));
    });
    _audioPlayer.positionStream.listen(_onPositionChange);
    _audioPlayer.playerStateStream.listen(_onPlayerStateChange);
  }

  void _onPlayerStateChange(PlayerState state) {
    final controls = mediaItem.valueOrNull == null
        ? const <MediaControl>[]
        : [state.playing ? MediaControl.pause : MediaControl.play];
    final systemActions = mediaItem.valueOrNull == null
        ? const <MediaAction>{}
        : const {MediaAction.playPause};
    final androidCompactActionIndices = mediaItem.valueOrNull == null ? null : const [0];
    playbackState.add(
      playbackState.value.copyWith(
        playing: state.playing,
        controls: controls,
        systemActions: systemActions,
        androidCompactActionIndices: androidCompactActionIndices,
        processingState: switch (state.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
      ),
    );
  }

  void _onPositionChange(Duration position) async {
    final playerInfo = _playerInfo;
    if (playerInfo == null) return;
    playbackState.add(playbackState.value.copyWith(updatePosition: position));

    //handle loop reseek
    final loopIndex = playerInfo.loopIndex;
    final loopSentence = loopIndex == null
        ? null
        : playerInfo.sentenceList.elementAtOrNull(loopIndex);
    if (loopSentence != null && position > loopSentence.end) {
      //if repeat one is turn on, while sentence finished, seek to beginning
      //reseek loop sentence
      // await _audioPlayer.seekTo(completedLoopSentence.start);
      await _audioPlayer.seek(loopSentence.start);
    }
    //auto-replay, if position >= duration,
    if (position >= playerInfo.duration) {
      _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
    }
  }

  void _onSyncFromPlayer(HubSyncPlayerToBackgroundAudioEvent event) async {
    final playerInfo = event.info;
    _playerInfo = playerInfo;
    final mediaFile = await playerInfo.media.file;
    final path = mediaFile?.path;
    if (path == null) return;
    final media = playerInfo.media;
    final album = p.basename(p.dirname(path));
    final artUri = (await media.thumbAsync(playerInfo.position))?.uri;
    // Update notification UI first to satisfy system requirements immediately
    mediaItem.add(
      MediaItem(
        id: media.id,
        title: await media.titleAsync,
        album: album,
        duration: playerInfo.duration,
        artUri: artUri,
      ),
    );

    // Fix mediaItem not showing, audioPlayer control codes, must below updateItem
    // Then setup the audio engine
    await _audioPlayer.setAudioSource(AudioSource.file(path));
    await _audioPlayer.setVolume(playerInfo.volume);
    await _audioPlayer.seek(playerInfo.position);
    await _audioPlayer.setSpeed(playerInfo.speed);
    if (playerInfo.playing) {
      await _audioPlayer.play();
    } else {
      await _audioPlayer.pause();
    }
  }

  void _onAppResume(HubAppResumeEvent event) async {
    if (mediaItem.valueOrNull == null) return;
    final playing = playbackState.value.playing;
    final position = playbackState.value.position;
    i('Syncing back to player UI: playing=$playing, position=${position.desc}');
    //remove mediaItem, stop audio player
    mediaItem.add(null);
    await _audioPlayer.stop();
    //emit event, player may start to play
    EventHub.emit(HubSyncBackgroundAudioToPlayerEvent(playing: playing, position: position));
  }

  @override
  Future<void> play() async {
    await _audioPlayer.play();
  }

  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    if (_playerInfo?.loopIndex != null) {
      final spot = _playerInfo?.sentenceList.spot(position);
      _playerInfo?.copyWith(loopIndex: () => spot?.index);
    }
    await _audioPlayer.seek(position);
  }

  // @override
  // Future<void> stop() async {
  //   await _mediaController.mb_pause();
  //   playbackState.add(
  //     playbackState.value.copyWith(
  //       playing: false,
  //       processingState: AudioProcessingState.idle,
  //     ),
  //   );
  //   await super.stop();
  // }
}

extension on AssetEntity {
  Future<File?> thumbAsync(Duration position) async {
    final file = await this.file;
    if (file == null) return null;

    final thumbData = await VideoThumbnail.thumbnailData(
      video: file.path,
      imageFormat: ImageFormat.JPEG,
      timeMs: position.inMilliseconds,
      maxWidth: 300,
      quality: 75,
    );

    if (thumbData == null) return null;

    final dir = await getTemporaryDirectory();
    final title = await titleAsync;
    final fileName = '$title-${size.width}x${size.height}-${DateTime.now().millisecondsSinceEpoch}';
    final thumbFile = File(p.join(dir.path, fileName));
    await thumbFile.writeAsBytes(thumbData, flush: true);
    return thumbFile;
  }
}
