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

// Notifier para gerenciar o estado assíncrono das buscas
class ExploreSearchNotifier extends StateNotifier<AsyncValue<List<YoutubeVideoResult>>> {
  final ExploreRepository _repository;

  ExploreSearchNotifier(this._repository) : super(const AsyncValue.data([]));

  // Executa a busca assíncrona
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final results = await _repository.searchVideos(query);
      state = AsyncValue.data(results);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Provider global para acessar a busca de vídeos
final exploreSearchProvider = StateNotifierProvider<ExploreSearchNotifier, AsyncValue<List<YoutubeVideoResult>>>((ref) {
  final repository = ref.watch(exploreRepositoryProvider);
  return ExploreSearchNotifier(repository);
});
