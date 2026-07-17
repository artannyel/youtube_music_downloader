import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as yt_play;
import '../../../../features/downloader_engine/data/services/extractor_service.dart';

enum PlaybackStatus { idle, loading, playing, paused, completed, error }
enum PlaybackSource { online, offline }
enum PlaybackMediaType { video, audio }

class PlayerMediaItem {
  final String id; // ID do vídeo no YouTube
  final String title;
  final String artist;
  final String thumbnailUrl;
  final String url; // URL do YouTube ou caminho local
  final String? localPath;

  const PlayerMediaItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    required this.url,
    this.localPath,
  });

  PlayerMediaItem copyWith({
    String? id,
    String? title,
    String? artist,
    String? thumbnailUrl,
    String? url,
    String? localPath,
  }) {
    return PlayerMediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      url: url ?? this.url,
      localPath: localPath ?? this.localPath,
    );
  }
}

class PlayerState {
  final PlaybackStatus status;
  final PlaybackSource source;
  final PlaybackMediaType mediaType;
  final PlayerMediaItem? currentItem;
  final List<PlayerMediaItem> queue;
  final int currentQueueIndex;
  final Duration position;
  final Duration duration;
  final String? errorMessage;

  const PlayerState({
    required this.status,
    required this.source,
    required this.mediaType,
    this.currentItem,
    required this.queue,
    required this.currentQueueIndex,
    required this.position,
    required this.duration,
    this.errorMessage,
  });

  const PlayerState.initial()
      : status = PlaybackStatus.idle,
        source = PlaybackSource.online,
        mediaType = PlaybackMediaType.audio,
        currentItem = null,
        queue = const [],
        currentQueueIndex = -1,
        position = Duration.zero,
        duration = Duration.zero,
        errorMessage = null;

  PlayerState copyWith({
    PlaybackStatus? status,
    PlaybackSource? source,
    PlaybackMediaType? mediaType,
    PlayerMediaItem? currentItem,
    List<PlayerMediaItem>? queue,
    int? currentQueueIndex,
    Duration? position,
    Duration? duration,
    String? errorMessage,
    bool clearCurrentItem = false,
  }) {
    return PlayerState(
      status: status ?? this.status,
      source: source ?? this.source,
      mediaType: mediaType ?? this.mediaType,
      currentItem: clearCurrentItem ? null : (currentItem ?? this.currentItem),
      queue: queue ?? this.queue,
      currentQueueIndex: currentQueueIndex ?? this.currentQueueIndex,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class PlayerNotifier extends StateNotifier<PlayerState> {
  // Players internos
  final AudioPlayer _audioPlayer = AudioPlayer();
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  yt_play.YoutubePlayerController? _ytController;

  // Streams de áudio
  final List<StreamSubscription<dynamic>> _audioSubs = [];

  PlayerNotifier() : super(const PlayerState.initial()) {
    _setupAudioListeners();
  }

  void _setupAudioListeners() {
    _audioSubs.add(_audioPlayer.positionStream.listen((pos) {
      if (state.mediaType == PlaybackMediaType.audio) {
        state = state.copyWith(position: pos);
      }
    }));

    _audioSubs.add(_audioPlayer.durationStream.listen((dur) {
      if (state.mediaType == PlaybackMediaType.audio && dur != null) {
        state = state.copyWith(duration: dur);
      }
    }));

    _audioSubs.add(_audioPlayer.playerStateStream.listen((playerState) {
      if (state.mediaType != PlaybackMediaType.audio) return;

      if (playerState.processingState == ProcessingState.loading ||
          playerState.processingState == ProcessingState.buffering) {
        state = state.copyWith(status: PlaybackStatus.loading);
      } else if (playerState.processingState == ProcessingState.ready) {
        state = state.copyWith(
          status: playerState.playing ? PlaybackStatus.playing : PlaybackStatus.paused,
        );
      } else if (playerState.processingState == ProcessingState.completed) {
        state = state.copyWith(status: PlaybackStatus.completed);
        playNext(); // Autoplay da fila
      }
    }));
  }

  /// Carrega e inicia a reprodução de um item de mídia.
  Future<void> loadMedia(
    PlayerMediaItem item, {
    required PlaybackSource source,
    required PlaybackMediaType mediaType,
    List<PlayerMediaItem> newQueue = const [],
  }) async {
    // 1. Limpa players ativos anteriores
    await stop();

    // 2. Atualiza estado inicial de carregamento
    final updatedQueue = newQueue.isNotEmpty ? newQueue : [item];
    final queueIndex = updatedQueue.indexWhere((x) => x.id == item.id);

    state = state.copyWith(
      status: PlaybackStatus.loading,
      source: source,
      mediaType: mediaType,
      currentItem: item,
      queue: updatedQueue,
      currentQueueIndex: queueIndex >= 0 ? queueIndex : 0,
      position: Duration.zero,
      duration: Duration.zero,
      errorMessage: null,
    );

    try {
      if (mediaType == PlaybackMediaType.audio) {
        // ---- PLAYER DE ÁUDIO (Online / Offline) ----
        if (source == PlaybackSource.offline && item.localPath != null) {
          final file = File(item.localPath!);
          if (!await file.exists()) {
            throw FileSystemException('Arquivo local não encontrado', item.localPath);
          }
          await _audioPlayer.setFilePath(item.localPath!);
        } else {
          // Streaming online: usa yt-dlp para extrair URL do stream de áudio.
          // O youtube_explode_dart falha com o novo challenge JS do YouTube;
          // o yt-dlp (via ExtractorService) resolve corretamente.
          final videoUrl = 'https://www.youtube.com/watch?v=${item.id}';
          final info = await ExtractorService.instance.getVideoInfoWithOptions(
            videoUrl,
            {'--format': 'bestaudio'},
          );

          // Tenta pegar URL diretamente do formato selecionado
          String? streamUrl = info.url;

          // Fallback: procura nos formatos o de melhor áudio
          if ((streamUrl == null || streamUrl.isEmpty) &&
              info.formats != null &&
              info.formats!.isNotEmpty) {
            // Filtra formatos que tenham URL e áudio (vcodec == 'none' = só áudio)
            final audioFormats = info.formats!
                .where((f) =>
                    f != null &&
                    f.url != null &&
                    f.url!.isNotEmpty &&
                    (f.vcodec == 'none' || f.vcodec == null))
                .toList();

            if (audioFormats.isNotEmpty) {
              // Pega o de maior taxa de bits
              audioFormats.sort((a, b) => (b?.tbr ?? 0).compareTo(a?.tbr ?? 0));
              streamUrl = audioFormats.first!.url;
            } else {
              // Usa qualquer formato disponível com URL
              final any = info.formats!.firstWhere(
                (f) => f?.url != null && f!.url!.isNotEmpty,
                orElse: () => null,
              );
              streamUrl = any?.url;
            }
          }

          if (streamUrl == null || streamUrl.isEmpty) {
            throw Exception('Não foi possível obter a URL do stream de áudio.');
          }

          await _audioPlayer.setUrl(streamUrl);
        }
        await _audioPlayer.play();
      } else {
        // ---- PLAYER DE VÍDEO (Online / Offline) ----
        if (source == PlaybackSource.offline && item.localPath != null) {
          final file = File(item.localPath!);
          if (!await file.exists()) {
            throw FileSystemException('Arquivo local não encontrado', item.localPath);
          }
          _videoPlayerController = VideoPlayerController.file(file);
          await _videoPlayerController!.initialize();

          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController!,
            autoPlay: true,
            looping: false,
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            errorBuilder: (context, errorMessage) {
              return Center(child: Text('Erro no vídeo: $errorMessage', style: const TextStyle(color: Colors.white)));
            },
          );

          // Escuta conclusão do vídeo
          _videoPlayerController!.addListener(_videoPlayerListener);

          state = state.copyWith(
            status: PlaybackStatus.playing,
            duration: _videoPlayerController!.value.duration,
          );
        } else {
          // Player de vídeo do YouTube (IFrame renderizado na UI)
          _ytController = yt_play.YoutubePlayerController(
            initialVideoId: item.id,
            flags: const yt_play.YoutubePlayerFlags(
              autoPlay: true,
              mute: false,
              hideControls: false,
            ),
          );

          // Escuta conclusão do vídeo online do YouTube
          _ytController!.addListener(_youtubePlayerListener);

          state = state.copyWith(
            status: PlaybackStatus.playing,
            duration: Duration.zero, // Gerenciado internamente pelo YoutubePlayerController
          );
        }
      }
    } catch (e) {
      debugPrint('[PlayerNotifier] Erro ao carregar mídia: $e');
      state = state.copyWith(
        status: PlaybackStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void _videoPlayerListener() {
    if (_videoPlayerController == null) return;

    final value = _videoPlayerController!.value;
    state = state.copyWith(
      position: value.position,
      status: value.isPlaying
          ? PlaybackStatus.playing
          : (value.position >= value.duration ? PlaybackStatus.completed : PlaybackStatus.paused),
    );

    if (value.position >= value.duration && state.status == PlaybackStatus.completed) {
      _videoPlayerController!.removeListener(_videoPlayerListener);
      playNext();
    }
  }

  void _youtubePlayerListener() {
    if (_ytController == null) return;

    final value = _ytController!.value;
    final isEnded = value.playerState == yt_play.PlayerState.ended;

    state = state.copyWith(
      position: value.position,
      duration: value.metaData.duration,
      status: isEnded
          ? PlaybackStatus.completed
          : (value.isPlaying ? PlaybackStatus.playing : PlaybackStatus.paused),
    );

    if (isEnded) {
      debugPrint('[PlayerNotifier] YouTube video ended. Loading next media...');
      _ytController!.removeListener(_youtubePlayerListener);
      playNext();
    }
  }

  // ---- Getters de Controllers para a UI ----

  ChewieController? get chewieController => _chewieController;
  yt_play.YoutubePlayerController? get youtubePlayerController => _ytController;

  // ---- Controles básicos --------------------------------------------------

  Future<void> play() async {
    if (state.mediaType == PlaybackMediaType.audio) {
      await _audioPlayer.play();
    } else if (state.mediaType == PlaybackMediaType.video) {
      if (state.source == PlaybackSource.offline) {
        await _videoPlayerController?.play();
      } else {
        _ytController?.play();
      }
    }
  }

  Future<void> pause() async {
    if (state.mediaType == PlaybackMediaType.audio) {
      await _audioPlayer.pause();
    } else if (state.mediaType == PlaybackMediaType.video) {
      if (state.source == PlaybackSource.offline) {
        await _videoPlayerController?.pause();
      } else {
        _ytController?.pause();
      }
    }
  }

  Future<void> seek(Duration pos) async {
    if (state.mediaType == PlaybackMediaType.audio) {
      await _audioPlayer.seek(pos);
    } else if (state.mediaType == PlaybackMediaType.video) {
      if (state.source == PlaybackSource.offline) {
        await _videoPlayerController?.seekTo(pos);
      } else {
        _ytController?.seekTo(pos);
      }
    }
  }

  Future<void> stop() async {
    // Para áudio
    await _audioPlayer.stop();

    // Limpa vídeo local
    if (_videoPlayerController != null) {
      _videoPlayerController!.removeListener(_videoPlayerListener);
      await _videoPlayerController!.dispose();
      _videoPlayerController = null;
    }
    if (_chewieController != null) {
      _chewieController!.dispose();
      _chewieController = null;
    }

    // Limpa player do YouTube
    if (_ytController != null) {
      _ytController!.removeListener(_youtubePlayerListener);
      _ytController!.dispose();
      _ytController = null;
    }

    state = state.copyWith(
      status: PlaybackStatus.idle,
      position: Duration.zero,
      duration: Duration.zero,
    );
  }

  // ---- Navegação de Fila -------------------------------------------------

  Future<void> playNext() async {
    if (state.queue.isEmpty) return;

    final nextIndex = state.currentQueueIndex + 1;
    if (nextIndex < state.queue.length) {
      await loadMedia(
        state.queue[nextIndex],
        source: state.source,
        mediaType: state.mediaType,
        newQueue: state.queue,
      );
    } else {
      debugPrint('[PlayerNotifier] Fim da fila de reprodução.');
    }
  }

  Future<void> playPrevious() async {
    if (state.queue.isEmpty) return;

    final prevIndex = state.currentQueueIndex - 1;
    if (prevIndex >= 0) {
      await loadMedia(
        state.queue[prevIndex],
        source: state.source,
        mediaType: state.mediaType,
        newQueue: state.queue,
      );
    }
  }

  @override
  void dispose() {
    for (var sub in _audioSubs) {
      sub.cancel();
    }
    _audioPlayer.dispose();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _ytController?.dispose();
    super.dispose();
  }
}

final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier();
});
