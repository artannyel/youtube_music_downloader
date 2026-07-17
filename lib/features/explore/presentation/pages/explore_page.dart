import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/explore_provider.dart';
import '../../domain/entities/youtube_video_result.dart';
import '../../../media_player/presentation/providers/player_provider.dart';
import '../../../download_setup/domain/utils/youtube_url_helper.dart';

class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _triggerSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    _searchFocusNode.unfocus();

    // 1. Verifica se são múltiplos links
    final multipleUrls = YoutubeUrlHelper.parseMultipleUrls(query);
    if (multipleUrls.length > 1) {
      context.push('/batch-details', extra: multipleUrls);
      return;
    }

    // 2. Verifica se é um único link do YouTube/YouTube Music ou ID
    if (YoutubeUrlHelper.isValidYoutubeInput(query)) {
      final normalUrl = YoutubeUrlHelper.convertMusicToNormalUrl(query);
      if (YoutubeUrlHelper.isPlaylist(normalUrl)) {
        final playlistId = YoutubeUrlHelper.extractPlaylistId(normalUrl);
        if (playlistId != null) {
          context.push('/playlist', extra: playlistId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ID de Playlist inválido')),
          );
        }
      } else {
        context.push('/download-setup', extra: normalUrl);
      }
      return;
    }

    // 3. Caso contrário, faz pesquisa padrão por termo de busca
    ref.read(exploreSearchProvider.notifier).search(query, isPlaylist: false);
    ref.read(explorePlaylistSearchProvider.notifier).search(query, isPlaylist: true);
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '';
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      final hours = duration.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  String _formatViews(int? views) {
    if (views == null) return '';
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M visualizações';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(0)}K visualizações';
    }
    return '$views visualizações';
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(exploreSearchProvider);
    final playlistSearchState = ref.watch(explorePlaylistSearchProvider);
    final theme = Theme.of(context);

    // Determina se há alguma pesquisa ativa para exibir as abas
    final isSearchActive = _searchController.text.trim().isNotEmpty &&
        (searchState.results.isNotEmpty ||
            playlistSearchState.results.isNotEmpty ||
            searchState.isLoading ||
            playlistSearchState.isLoading ||
            searchState.errorMessage != null ||
            playlistSearchState.errorMessage != null);

    Widget mainContent;
    if (!isSearchActive) {
      mainContent = _buildEmptyState(theme);
    } else {
      mainContent = Column(
        children: [
          TabBar(
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.outline,
            tabs: const [
              Tab(icon: Icon(Icons.video_library_rounded), text: 'Vídeos'),
              Tab(icon: Icon(Icons.featured_play_list_rounded), text: 'Playlists'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              children: [
                _buildBody(searchState, theme, isPlaylist: false),
                _buildBody(playlistSearchState, theme, isPlaylist: true),
              ],
            ),
          ),
        ],
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Explorar',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.link, color: Colors.white),
              tooltip: 'Colar Link(s) ou Playlist',
              onPressed: () => _showPasteLinkDialog(context),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Barra de Pesquisa Moderna
              TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _triggerSearch(),
                decoration: InputDecoration(
                  hintText: 'Pesquise músicas ou vídeos...',
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (text) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              
              // Corpo Principal da Tela
              Expanded(
                child: mainContent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ExploreState state, ThemeData theme, {required bool isPlaylist}) {
    if (state.isLoading) {
      return _buildShimmerLoading();
    }
    
    if (state.errorMessage != null && state.results.isEmpty) {
      return _buildErrorState(state.errorMessage!, theme, isPlaylist: isPlaylist);
    }
    
    if (state.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPlaylist ? Icons.featured_play_list_outlined : Icons.video_library_outlined,
              size: 64,
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isPlaylist ? 'Nenhuma playlist encontrada' : 'Nenhum vídeo encontrado',
              style: TextStyle(color: theme.colorScheme.outline),
            ),
          ],
        ),
      );
    }
    
    return _buildResultsList(state, theme, isPlaylist: isPlaylist);
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.youtube_searched_for,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 16),
            Text(
              'Encontre sua mídia favorita',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Insira termos de busca ou palavras-chave\npara listar resultados do YouTube.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _showPasteLinkDialog(context),
              icon: const Icon(Icons.link),
              label: const Text(
                'Colar Link de Música, Vídeo ou Playlist',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, ThemeData theme, {required bool isPlaylist}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Ops! Ocorreu um erro',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _triggerSearch,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(ExploreState state, ThemeData theme, {required bool isPlaylist}) {
    final results = state.results;
    
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
          if (isPlaylist) {
            ref.read(explorePlaylistSearchProvider.notifier).loadMore();
          } else {
            ref.read(exploreSearchProvider.notifier).loadMore();
          }
        }
        return false;
      },
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: results.length + (state.isLoadingMore || state.errorMessage != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == results.length) {
            if (state.isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (state.errorMessage != null) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  children: [
                    Text(
                      'Erro ao carregar mais resultados.',
                      style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (isPlaylist) {
                          ref.read(explorePlaylistSearchProvider.notifier).loadMore();
                        } else {
                          ref.read(exploreSearchProvider.notifier).loadMore();
                        }
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Tentar carregar mais'),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }

          final YoutubeVideoResult video = results[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: InkWell(
              onTap: () {
                if (isPlaylist) {
                  context.push('/playlist', extra: video.id);
                } else {
                  ref.read(playerProvider.notifier).loadMedia(
                    PlayerMediaItem(
                      id: video.id,
                      title: video.title,
                      artist: video.author,
                      thumbnailUrl: video.thumbnailUrl,
                      url: 'https://youtube.com/watch?v=${video.id}',
                    ),
                    source: PlaybackSource.online,
                    mediaType: PlaybackMediaType.video,
                  );
                  context.push('/player');
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Card(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Capa do Vídeo com duração ou quantidade de faixas
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              video.thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.broken_image, size: 50),
                              ),
                            ),
                          ),
                        ),
                        if (!isPlaylist && video.duration != null)
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _formatDuration(video.duration),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        if (isPlaylist && video.playlistVideoCount != null)
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.playlist_play_rounded, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${video.playlistVideoCount} faixas',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Detalhes da Mídia
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.15),
                            radius: 18,
                            child: Text(
                              isPlaylist ? 'PL' : (video.author.isNotEmpty ? video.author[0].toUpperCase() : 'Y'),
                              style: TextStyle(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  video.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isPlaylist
                                            ? 'Playlist do YouTube'
                                            : '${video.author} • ${_formatViews(video.viewCount)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Card(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white10,
                        radius: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 14,
                              width: double.infinity,
                              color: Colors.white10,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 12,
                              width: 150,
                              color: Colors.white10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPasteLinkDialog(BuildContext context) {
    final TextEditingController linkController = TextEditingController();
    String? localError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.link, color: Colors.blueAccent),
                  SizedBox(width: 8),
                  Text('Colar Link(s) ou Playlist'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Cole links do YouTube ou YouTube Music abaixo. Para baixar múltiplos links em lote, separe-os por quebra de linha ou vírgula.',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: linkController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Ex:\nhttps://www.youtube.com/watch?v=...\nhttps://music.youtube.com/watch?v=...',
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.white30),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      errorText: localError,
                    ),
                    onChanged: (_) {
                      if (localError != null) {
                        setDialogState(() {
                          localError = null;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final text = linkController.text.trim();
                    if (text.isEmpty) {
                      setDialogState(() {
                        localError = 'O campo de links não pode ser vazio.';
                      });
                      return;
                    }

                    final parsedUrls = YoutubeUrlHelper.parseMultipleUrls(text);
                    if (parsedUrls.isEmpty) {
                      setDialogState(() {
                        localError = 'Nenhum link do YouTube válido foi encontrado.';
                      });
                      return;
                    }

                    Navigator.pop(context);

                    if (parsedUrls.length > 1) {
                      context.push('/batch-details', extra: parsedUrls);
                    } else {
                      final singleUrl = parsedUrls.first;
                      if (YoutubeUrlHelper.isPlaylist(singleUrl)) {
                        final playlistId = YoutubeUrlHelper.extractPlaylistId(singleUrl);
                        if (playlistId != null) {
                          context.push('/playlist', extra: playlistId);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ID de Playlist inválido')),
                          );
                        }
                      } else {
                        context.push('/download-setup', extra: singleUrl);
                      }
                    }
                  },
                  child: const Text('Prosseguir'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
