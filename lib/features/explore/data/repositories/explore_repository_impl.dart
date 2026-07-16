import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_explode;
import '../../domain/entities/youtube_video_result.dart';
import '../../domain/repositories/explore_repository.dart';

class ExploreRepositoryImpl implements ExploreRepository {
  final yt_explode.YoutubeExplode _yt;
  yt_explode.VideoSearchList? _currentSearchList;

  ExploreRepositoryImpl(this._yt);

  List<YoutubeVideoResult> _mapResults(Iterable<yt_explode.Video> list) {
    return list.map((video) {
      return YoutubeVideoResult(
        id: video.id.value,
        title: video.title,
        author: video.author,
        duration: video.duration,
        thumbnailUrl: video.thumbnails.mediumResUrl,
        viewCount: video.engagement.viewCount,
      );
    }).toList();
  }

  @override
  Future<List<YoutubeVideoResult>> searchVideos(String query) async {
    try {
      final searchResults = await _yt.search.search(query);
      _currentSearchList = searchResults;
      return _mapResults(searchResults);
    } catch (e) {
      throw Exception('Erro ao buscar vídeos: $e');
    }
  }

  @override
  Future<List<YoutubeVideoResult>> nextSearchPage() async {
    if (_currentSearchList == null) return [];
    try {
      final nextPageResults = await _currentSearchList!.nextPage();
      _currentSearchList = nextPageResults;
      if (nextPageResults == null) return [];
      return _mapResults(nextPageResults);
    } catch (e) {
      throw Exception('Erro ao carregar próxima página: $e');
    }
  }

  @override
  Future<List<YoutubeVideoResult>> getRelatedVideos(String videoId) async {
    try {
      final video = await _yt.videos.get(videoId);
      final relatedVideos = await _yt.videos.getRelatedVideos(video);
      if (relatedVideos == null) return [];
      
      return relatedVideos.map((vid) {
        return YoutubeVideoResult(
          id: vid.id.value,
          title: vid.title,
          author: vid.author,
          duration: vid.duration,
          thumbnailUrl: vid.thumbnails.mediumResUrl,
          viewCount: vid.engagement.viewCount,
        );
      }).toList();
    } catch (e) {
      throw Exception('Erro ao obter vídeos relacionados: $e');
    }
  }
}
