import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class PlaylistData {
  final Playlist metadata;
  final List<Video> videos;

  const PlaylistData({required this.metadata, required this.videos});
}

final playlistDetailsProvider = FutureProvider.family<PlaylistData, String>((ref, playlistId) async {
  final yt = YoutubeExplode();
  try {
    final metadata = await yt.playlists.get(playlistId);
    final videos = await yt.playlists.getVideos(playlistId).toList();
    return PlaylistData(metadata: metadata, videos: videos);
  } finally {
    yt.close();
  }
});
