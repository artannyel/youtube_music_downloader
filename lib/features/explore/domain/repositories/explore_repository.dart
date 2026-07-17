import '../entities/youtube_video_result.dart';

abstract class ExploreRepository {
  Future<List<YoutubeVideoResult>> searchVideos(String query);
  Future<List<YoutubeVideoResult>> searchPlaylists(String query);
  Future<List<YoutubeVideoResult>> nextSearchPage();
  Future<List<YoutubeVideoResult>> getRelatedVideos(String videoId);
}
