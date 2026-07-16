import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';

class PlaylistDetailsPage extends ConsumerWidget {
  final String playlistId;

  const PlaylistDetailsPage({super.key, required this.playlistId});

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (playlistId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Playlist')),
        body: const Center(
          child: Text('Identificador de playlist inválido.'),
        ),
      );
    }

    final playlistAsync = ref.watch(playlistDetailsProvider(playlistId));

    return Scaffold(
      body: playlistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Scaffold(
          appBar: AppBar(title: const Text('Playlist')),
          body: Center(child: Text('Erro ao carregar playlist: $err')),
        ),
        data: (data) {
          final metadata = data.metadata;
          final videos = data.videos;
          final thumbnailUrl = metadata.thumbnails.mediumResUrl;

          // Mapeia os vídeos do youtube_explode para PlayerMediaItem
          final mediaItems = videos.map((video) {
            return PlayerMediaItem(
              id: video.id.value,
              title: video.title,
              artist: video.author,
              thumbnailUrl: video.thumbnails.mediumResUrl,
              url: video.url,
            );
          }).toList();

          return CustomScrollView(
            slivers: [
              // -------------------------------------------------------------
              // 1. CABEÇALHO SLIVER COM THUMBNAIL E DETALHES
              // -------------------------------------------------------------
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    metadata.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      shadows: [Shadow(blurRadius: 10, color: Colors.black54)],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                      ),
                      // Overlay escuro com gradiente
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black54, Colors.black87],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        bottom: 48,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              metadata.author,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${videos.length} faixas',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // -------------------------------------------------------------
              // 2. BOTÃO BULK DOWNLOAD DE PLAYLIST
              // -------------------------------------------------------------
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.download_for_offline),
                    label: const Text(
                      'Baixar Tudo (Lote)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    onPressed: () {
                      context.push('/download-setup', extra: metadata.url);
                    },
                  ),
                ),
              ),

              // -------------------------------------------------------------
              // 3. LISTAGEM DE FAIXAS DA PLAYLIST
              // -------------------------------------------------------------
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final video = videos[index];
                    final item = mediaItems[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            video.thumbnails.mediumResUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: theme.colorScheme.primary.withValues(alpha: 0.05),
                              width: 60,
                              height: 60,
                              child: const Icon(Icons.music_note),
                            ),
                          ),
                        ),
                        title: Text(
                          video.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '${video.author} • ${_formatDuration(video.duration)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.play_circle_fill, color: theme.colorScheme.primary, size: 28),
                          onPressed: () {
                            // Carrega a playlist na fila e reproduz o item clicado
                            ref.read(playerProvider.notifier).loadMedia(
                                  item,
                                  source: PlaybackSource.online,
                                  mediaType: PlaybackMediaType.audio, // Padrão áudio
                                  newQueue: mediaItems,
                                );
                            context.push('/player');
                          },
                        ),
                      ),
                    );
                  },
                  childCount: videos.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
