import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_explode;
import '../../domain/entities/youtube_video_result.dart';
import '../../domain/repositories/explore_repository.dart';

class ExploreRepositoryImpl implements ExploreRepository {
  final yt_explode.YoutubeExplode _yt;

  ExploreRepositoryImpl(this._yt);

  @override
  Future<List<YoutubeVideoResult>> searchVideos(String query) async {
    try {
      final searchResults = await _yt.search.search(query);
      return searchResults.map((video) {
        return YoutubeVideoResult(
          id: video.id.value,
          title: video.title,
          author: video.author,
          duration: video.duration,
          thumbnailUrl: video.thumbnails.mediumResUrl,
          viewCount: video.engagement.viewCount,
        );
      }).toList();
    } catch (e) {
      throw Exception('Erro ao buscar vídeos: $e');
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
