import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_exp;
import '../providers/player_provider.dart';
import '../widgets/online_youtube_player.dart';
import '../widgets/offline_media_player.dart';
import '../widgets/queue_bottom_sheet.dart';

// Provider para buscar vídeos relacionados usando youtube_explode_dart
final relatedVideosProvider = FutureProvider.family<List<yt_exp.Video>, String>((ref, videoId) async {
  final yt = yt_exp.YoutubeExplode();
  try {
    final video = await yt.videos.get(yt_exp.VideoId(videoId));
    final related = await yt.videos.getRelatedVideos(video);
    return related?.toList() ?? [];
  } catch (_) {
    return [];
  } finally {
    yt.close();
  }
});

class MediaPlayerPage extends ConsumerStatefulWidget {
  const MediaPlayerPage({super.key});

  @override
  ConsumerState<MediaPlayerPage> createState() => _MediaPlayerPageState();
}

class _MediaPlayerPageState extends ConsumerState<MediaPlayerPage> {
  bool _isDescriptionExpanded = false;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  void _showQueue() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QueueBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerProvider);
    final theme = Theme.of(context);

    if (state.status == PlaybackStatus.idle || state.currentItem == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Player')),
        body: const Center(
          child: Text('Nenhuma mídia em reprodução no momento.'),
        ),
      );
    }

    final item = state.currentItem!;
    final isOnline = state.source == PlaybackSource.online;
    final isAudio = state.mediaType == PlaybackMediaType.audio;

    // Se for online e vídeo, o controle do progresso/duração é feito
    // internamente pelo controlador do YoutubePlayer.
    final hasYtVideoController = isOnline && !isAudio && state.status != PlaybackStatus.loading;

    // Busca vídeos relacionados se for online
    final relatedAsync = isOnline
        ? ref.watch(relatedVideosProvider(item.id))
        : const AsyncValue<List<yt_exp.Video>>.data([]);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(playerProvider.notifier).stop();
            context.pop();
          },
        ),
        title: Text(
          isOnline ? 'Reproduzindo Online' : 'Reproduzindo Offline',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music),
            tooltip: 'Fila de Reprodução',
            onPressed: _showQueue,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 12),
          // -----------------------------------------------------------------
          // 1. ZONA DO PLAYER (Topo)
          // -----------------------------------------------------------------
          if (state.status == PlaybackStatus.loading)
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(child: CircularProgressIndicator()),
            )
          else if (isOnline && !isAudio)
            // Player de Vídeo Online (YouTube)
            OnlineYoutubePlayer(
              controller: ref.read(playerProvider.notifier).youtubePlayerController!,
            )
          else
            // Player de Vídeo/Áudio Offline ou Áudio Online
            OfflineMediaPlayer(
              mediaType: state.mediaType,
              item: item,
              chewieController: ref.read(playerProvider.notifier).chewieController,
            ),

          const SizedBox(height: 20),

          // -----------------------------------------------------------------
          // 2. CONTROLES DE REPRODUÇÃO (Apenas para Áudio ou Vídeo Offline)
          // -----------------------------------------------------------------
          if (!hasYtVideoController) ...[
            // Slider de Progresso
            Slider(
              activeColor: theme.colorScheme.primary,
              inactiveColor: theme.colorScheme.primary.withValues(alpha: 0.15),
              value: state.position.inSeconds.toDouble().clamp(
                    0.0,
                    state.duration.inSeconds.toDouble() > 0
                        ? state.duration.inSeconds.toDouble()
                        : 1.0,
                  ),
              max: state.duration.inSeconds.toDouble() > 0
                  ? state.duration.inSeconds.toDouble()
                  : 1.0,
              onChanged: (val) {
                ref.read(playerProvider.notifier).seek(Duration(seconds: val.toInt()));
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(state.position), style: const TextStyle(fontSize: 12)),
                  Text(_formatDuration(state.duration), style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Botões de Ação Play/Pause/Mudar de Música
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.skip_previous_rounded),
                  onPressed: () => ref.read(playerProvider.notifier).playPrevious(),
                ),
                const SizedBox(width: 16),
                CircleAvatar(
                  radius: 36,
                  backgroundColor: theme.colorScheme.primary,
                  child: IconButton(
                    iconSize: 40,
                    color: Colors.white,
                    icon: Icon(
                      state.status == PlaybackStatus.playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    onPressed: () {
                      if (state.status == PlaybackStatus.playing) {
                        ref.read(playerProvider.notifier).pause();
                      } else {
                        ref.read(playerProvider.notifier).play();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.skip_next_rounded),
                  onPressed: () => ref.read(playerProvider.notifier).playNext(),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // -----------------------------------------------------------------
          // 3. INFORMAÇÕES DA MÍDIA
          // -----------------------------------------------------------------
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            item.artist,
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),

          // -----------------------------------------------------------------
          // 4. BOTÃO DE DOWNLOAD (Apenas se Online)
          // -----------------------------------------------------------------
          if (isOnline) ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.download_rounded),
              label: const Text('Configurar Download', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              onPressed: () {
                context.push('/download-setup', extra: item.url);
              },
            ),
            const SizedBox(height: 20),
          ],

          // -----------------------------------------------------------------
          // 5. DESCRIÇÃO COLLAPSE/EXPAND
          // -----------------------------------------------------------------
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  _isDescriptionExpanded = !_isDescriptionExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Detalhes do Conteúdo',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Icon(
                          _isDescriptionExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                        ),
                      ],
                    ),
                    if (_isDescriptionExpanded) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Título Completo: ${item.title}\n'
                        'Canal/Artista: ${item.artist}\n'
                        'Identificador YouTube: ${item.id}\n'
                        'Caminho de Arquivo: ${item.localPath ?? "Streaming Online"}',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // -----------------------------------------------------------------
          // 6. VÍDEOS RELACIONADOS (Apenas se Online)
          // -----------------------------------------------------------------
          if (isOnline) ...[
            const Text(
              'Vídeos Relacionados',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            relatedAsync.when(
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('Não foi possível carregar relacionados.', style: TextStyle(color: theme.colorScheme.error)),
              ),
              data: (videos) {
                if (videos.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Nenhum vídeo relacionado encontrado.'),
                  );
                }

                return SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: videos.length,
                    itemBuilder: (context, index) {
                      final video = videos[index];

                      return Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () {
                            ref.read(playerProvider.notifier).loadMedia(
                                  PlayerMediaItem(
                                    id: video.id.value,
                                    title: video.title,
                                    artist: video.author,
                                    thumbnailUrl: video.thumbnails.mediumResUrl,
                                    url: video.url,
                                  ),
                                  source: PlaybackSource.online,
                                  mediaType: state.mediaType,
                                );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  video.thumbnails.mediumResUrl,
                                  height: 80,
                                  width: 140,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.white10,
                                    height: 80,
                                    width: 140,
                                    child: const Icon(Icons.music_note, color: Colors.white30),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                video.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                              Text(
                                video.author,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}
