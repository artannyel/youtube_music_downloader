import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../../../core/utils/custom_playlist_helper.dart';

class PlaylistData {
  final Playlist metadata;
  final List<Video> videos;

  const PlaylistData({required this.metadata, required this.videos});
}

final playlistDetailsProvider = FutureProvider.family<PlaylistData, String>((ref, playlistId) async {
  final yt = YoutubeExplode();
  try {
    final metadata = await yt.playlists.get(playlistId);
    // Usa o helper customizado que suporta o novo formato lockupViewModel.
    final videos = await CustomPlaylistHelper.getPlaylistVideos(playlistId);
    return PlaylistData(metadata: metadata, videos: videos);
  } finally {
    yt.close();
  }
});
