import '../../../explore/domain/entities/youtube_video_result.dart';

class MediaMetadata {
  final String id;
  final String title;
  final String author;
  final String thumbnailUrl;
  final bool isPlaylist;
  final Duration? duration;
  final List<YoutubeVideoResult>? playlistVideos;
  final List<String> videoQualities;
  final List<String> audioQualities;

  const MediaMetadata({
    required this.id,
    required this.title,
    required this.author,
    required this.thumbnailUrl,
    required this.isPlaylist,
    this.duration,
    this.playlistVideos,
    required this.videoQualities,
    required this.audioQualities,
  });

  @override
  String toString() {
    return 'MediaMetadata(id: $id, title: $title, isPlaylist: $isPlaylist, playlistVideosCount: ${playlistVideos?.length})';
  }
}
