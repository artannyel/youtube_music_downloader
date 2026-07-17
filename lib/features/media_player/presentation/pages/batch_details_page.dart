import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/player_provider.dart';
import '../../../../features/download_setup/presentation/providers/download_setup_provider.dart';
import '../../../../features/download_setup/domain/entities/media_metadata.dart';
import '../../../../features/downloader_engine/presentation/widgets/batch_download_sheet.dart';

/// Provider que busca os metadados de múltiplos links em paralelo,
/// tolerando erros individuais (pula links com falha/inválidos).
final batchDetailsMetadataProvider = FutureProvider.family<List<MediaMetadata>, List<String>>((ref, urls) async {
  final repository = ref.watch(downloadSetupRepositoryProvider);
  final List<MediaMetadata> metadataList = [];

  for (final url in urls) {
    try {
      final meta = await repository.fetchMetadata(url);
      metadataList.add(meta);
    } catch (_) {
      // Ignora e continua para os outros links
    }
  }

  return metadataList;
});

class BatchDetailsPage extends ConsumerWidget {
  final List<String> urls;

  const BatchDetailsPage({super.key, required this.urls});

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

    if (urls.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fila em Lote')),
        body: const Center(
          child: Text('Nenhum link fornecido.'),
        ),
      );
    }

    final metadataAsync = ref.watch(batchDetailsMetadataProvider(urls));

    return Scaffold(
      body: metadataAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Obtendo informações dos links...',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        error: (err, stack) => Scaffold(
          appBar: AppBar(title: const Text('Fila em Lote')),
          body: Center(child: Text('Erro ao carregar detalhes: $err')),
        ),
        data: (metaList) {
          if (metaList.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('Fila em Lote')),
              body: const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'Não foi possível obter informações de nenhum dos links inseridos. Verifique a conexão ou os links.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }

          // Mapeia os metadados para PlayerMediaItem
          final mediaItems = metaList.map((meta) {
            return PlayerMediaItem(
              id: meta.id,
              title: meta.title,
              artist: meta.author,
              thumbnailUrl: meta.thumbnailUrl,
              url: 'https://youtube.com/watch?v=${meta.id}',
            );
          }).toList();

          return CustomScrollView(
            slivers: [
              // 1. App Bar Sliver com efeito gradiente premium
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Download em Lote',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      shadows: [Shadow(blurRadius: 10, color: Colors.black54)],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (metaList.isNotEmpty)
                        Image.network(
                          metaList.first.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: theme.colorScheme.primaryContainer,
                          ),
                        ),
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
                              '${metaList.length} faixas encontradas',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Botão Bulk Download e Opções de Reprodução
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
                          // Abre o bottom sheet de configuração em lote
                          BatchDownloadSheet.show(context, urls);
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

              // 3. Lista dos itens colados
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final meta = metaList[index];
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
                              meta.thumbnailUrl,
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
                            meta.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '${meta.author} • ${_formatDuration(meta.duration)}',
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
                  childCount: metaList.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
