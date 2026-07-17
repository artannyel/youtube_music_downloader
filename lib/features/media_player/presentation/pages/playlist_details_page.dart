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

  void _showPlaybackTypeSelector({
    required BuildContext context,
    required WidgetRef ref,
    required PlayerMediaItem item,
    required List<PlayerMediaItem> mediaItems,
    required ThemeData theme,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Opções de Reprodução',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.music_note_rounded, color: theme.colorScheme.primary),
                ),
                title: const Text('Reproduzir como Áudio', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Foco em música, ideal para segundo plano'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(playerProvider.notifier).loadMedia(
                        item,
                        source: PlaybackSource.online,
                        mediaType: PlaybackMediaType.audio,
                        newQueue: mediaItems,
                      );
                  context.push('/player');
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.videocam_rounded, color: theme.colorScheme.primary),
                ),
                title: const Text('Reproduzir como Vídeo', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Exibir clipe completo com imagem e áudio'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(playerProvider.notifier).loadMedia(
                        item,
                        source: PlaybackSource.online,
                        mediaType: PlaybackMediaType.video,
                        newQueue: mediaItems,
                      );
                  context.push('/player');
                },
              ),
            ],
          ),
        );
      },
    );
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
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: theme.colorScheme.primaryContainer,
                          child: const Center(
                            child: Icon(
                              Icons.music_note_rounded,
                              size: 80,
                              color: Colors.white24,
                            ),
                          ),
                        ),
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
              // 2. BOTÃO BULK DOWNLOAD DE PLAYLIST & OPÇÕES DE PLAYLIST
              // -------------------------------------------------------------
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size(double.infinity, 48),
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(color: theme.colorScheme.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.music_note_rounded),
                              label: const Text('Ouvir tudo', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () {
                                if (mediaItems.isNotEmpty) {
                                  ref.read(playerProvider.notifier).loadMedia(
                                        mediaItems.first,
                                        source: PlaybackSource.online,
                                        mediaType: PlaybackMediaType.audio,
                                        newQueue: mediaItems,
                                      );
                                  context.push('/player');
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(color: theme.colorScheme.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.play_circle_fill_rounded),
                              label: const Text('Assistir tudo', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () {
                                if (mediaItems.isNotEmpty) {
                                  ref.read(playerProvider.notifier).loadMedia(
                                        mediaItems.first,
                                        source: PlaybackSource.online,
                                        mediaType: PlaybackMediaType.video,
                                        newQueue: mediaItems,
                                      );
                                  context.push('/player');
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
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
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showPlaybackTypeSelector(
                          context: context,
                          ref: ref,
                          item: item,
                          mediaItems: mediaItems,
                          theme: theme,
                        ),
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
                            onPressed: () => _showPlaybackTypeSelector(
                              context: context,
                              ref: ref,
                              item: item,
                              mediaItems: mediaItems,
                              theme: theme,
                            ),
                          ),
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
