import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_explode;
import '../../data/repositories/explore_repository_impl.dart';
import '../../domain/entities/youtube_video_result.dart';
import '../../domain/repositories/explore_repository.dart';

// Provider para gerenciar a instância global do YoutubeExplode
final youtubeExplodeProvider = Provider<yt_explode.YoutubeExplode>((ref) {
  final yt = yt_explode.YoutubeExplode();
  // Libera os recursos de rede ao descartar o provider
  ref.onDispose(() {
    yt.close();
  });
  return yt;
});

// Provider para injetar a implementação do ExploreRepository
final exploreRepositoryProvider = Provider<ExploreRepository>((ref) {
  final yt = ref.watch(youtubeExplodeProvider);
  return ExploreRepositoryImpl(yt);
});

// Estado personalizado para a tela de exploração e busca
class ExploreState {
  final List<YoutubeVideoResult> results;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final bool hasReachedEnd;

  const ExploreState({
    required this.results,
    required this.isLoading,
    required this.isLoadingMore,
    this.errorMessage,
    required this.hasReachedEnd,
  });

  const ExploreState.initial()
      : results = const [],
        isLoading = false,
        isLoadingMore = false,
        errorMessage = null,
        hasReachedEnd = false;

  ExploreState copyWith({
    List<YoutubeVideoResult>? results,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool? hasReachedEnd,
  }) {
    return ExploreState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
    );
  }
}

// Notifier para gerenciar a paginação e o estado de busca de vídeos e playlists
class ExploreSearchNotifier extends StateNotifier<ExploreState> {
  final ExploreRepository _repository;

  ExploreSearchNotifier(this._repository) : super(const ExploreState.initial());

  // Inicia uma nova busca
  Future<void> search(String query, {bool isPlaylist = false}) async {
    if (query.trim().isEmpty) {
      state = const ExploreState.initial();
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      results: [],
      hasReachedEnd: false,
    );

    try {
      final results = isPlaylist
          ? await _repository.searchPlaylists(query)
          : await _repository.searchVideos(query);
      state = state.copyWith(
        isLoading: false,
        results: results,
        hasReachedEnd: results.isEmpty,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // Carrega a próxima página de resultados
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || state.hasReachedEnd) return;

    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    try {
      final nextResults = await _repository.nextSearchPage();
      state = state.copyWith(
        isLoadingMore: false,
        results: [...state.results, ...nextResults],
        hasReachedEnd: nextResults.isEmpty,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

// Provider global para acessar a busca de vídeos
final exploreSearchProvider = StateNotifierProvider<ExploreSearchNotifier, ExploreState>((ref) {
  final repository = ref.watch(exploreRepositoryProvider);
  return ExploreSearchNotifier(repository);
});

// Provider global para acessar a busca de playlists
final explorePlaylistSearchProvider = StateNotifierProvider<ExploreSearchNotifier, ExploreState>((ref) {
  final repository = ref.watch(exploreRepositoryProvider);
  return ExploreSearchNotifier(repository);
});
