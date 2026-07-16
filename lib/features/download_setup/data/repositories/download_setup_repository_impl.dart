import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_explode;
import '../../domain/entities/media_metadata.dart';
import '../../domain/repositories/download_setup_repository.dart';
import '../../domain/utils/youtube_url_helper.dart';
import '../../../explore/domain/entities/youtube_video_result.dart';

class DownloadSetupRepositoryImpl implements DownloadSetupRepository {
  final yt_explode.YoutubeExplode _yt;

  DownloadSetupRepositoryImpl(this._yt);

  String _qualityLabel(yt_explode.VideoQuality quality) {
    switch (quality) {
      case yt_explode.VideoQuality.low144:
        return '144p';
      case yt_explode.VideoQuality.low240:
        return '240p';
      case yt_explode.VideoQuality.medium360:
        return '360p';
      case yt_explode.VideoQuality.medium480:
        return '480p';
      case yt_explode.VideoQuality.high720:
        return '720p';
      case yt_explode.VideoQuality.high1080:
        return '1080p';
      case yt_explode.VideoQuality.high1440:
        return '1440p';
      case yt_explode.VideoQuality.high2160:
        return '2160p';
      case yt_explode.VideoQuality.high2880:
        return '2880p';
      case yt_explode.VideoQuality.high4320:
        return '4320p';
      default:
        return 'Desconhecida';
    }
  }

  @override
  Future<MediaMetadata> fetchMetadata(String url) async {
    try {
      final normalizedUrl = YoutubeUrlHelper.convertMusicToNormalUrl(url);
      final isPlaylist = YoutubeUrlHelper.isPlaylist(normalizedUrl);

      if (isPlaylist) {
        final playlistId = YoutubeUrlHelper.extractPlaylistId(normalizedUrl);
        if (playlistId == null) {
          throw Exception('ID de Playlist inválido.');
        }

        final playlist = await _yt.playlists.get(playlistId);
        final playlistVideosStream = _yt.playlists.getVideos(playlist.id);
        final List<yt_explode.Video> videoList = await playlistVideosStream.toList();

        final playlistVideos = videoList.map((video) {
          return YoutubeVideoResult(
            id: video.id.value,
            title: video.title,
            author: video.author,
            duration: video.duration,
            thumbnailUrl: video.thumbnails.mediumResUrl,
            viewCount: video.engagement.viewCount,
          );
        }).toList();

        return MediaMetadata(
          id: playlist.id.value,
          title: playlist.title,
          author: playlist.author.isNotEmpty ? playlist.author : 'YouTube Playlist',
          thumbnailUrl: playlistVideos.isNotEmpty ? playlistVideos.first.thumbnailUrl : '',
          isPlaylist: true,
          playlistVideos: playlistVideos,
          // Fallbacks genéricos para playlists (a qualidade específica de cada vídeo será resolvida ao baixar)
          videoQualities: ['1080p', '720p', '480p', '360p'],
          audioQualities: ['Alta Qualidade (Opus/AAC)', 'Média Qualidade (Opus/AAC)'],
        );
      } else {
        final videoId = YoutubeUrlHelper.extractVideoId(normalizedUrl);
        if (videoId == null) {
          throw Exception('ID de Vídeo inválido.');
        }

        final video = await _yt.videos.get(videoId);
        final manifest = await _yt.videos.streams.getManifest(videoId);

        // Extrai qualidades de vídeo únicas
        final uniqueVideoQualities = <String>{};
        for (var stream in manifest.videoOnly) {
          final label = _qualityLabel(stream.videoQuality);
          if (label != 'Desconhecida') {
            uniqueVideoQualities.add(label);
          }
        }
        for (var stream in manifest.muxed) {
          final label = _qualityLabel(stream.videoQuality);
          if (label != 'Desconhecida') {
            uniqueVideoQualities.add(label);
          }
        }

        // Ordena do maior para o menor
        final videoQualities = uniqueVideoQualities.toList()
          ..sort((a, b) {
            final aVal = int.tryParse(RegExp(r'\d+').firstMatch(a)?.group(0) ?? '0') ?? 0;
            final bVal = int.tryParse(RegExp(r'\d+').firstMatch(b)?.group(0) ?? '0') ?? 0;
            return bVal.compareTo(aVal);
          });

        // Extrai qualidades de áudio
        final uniqueAudioQualities = <String>{};
        for (var stream in manifest.audioOnly) {
          // Podemos classificar com base no bitrate
          final kbps = (stream.bitrate.bitsPerSecond / 1000).round();
          if (kbps >= 120) {
            uniqueAudioQualities.add('Alta Qualidade ($kbps Kbps)');
          } else {
            uniqueAudioQualities.add('Média Qualidade ($kbps Kbps)');
          }
        }

        final audioQualities = uniqueAudioQualities.toList()
          ..sort((a, b) {
            final aVal = int.tryParse(RegExp(r'\d+').firstMatch(a)?.group(0) ?? '0') ?? 0;
            final bVal = int.tryParse(RegExp(r'\d+').firstMatch(b)?.group(0) ?? '0') ?? 0;
            return bVal.compareTo(aVal); // Do maior kbps para o menor
          });

        if (audioQualities.isEmpty) {
          audioQualities.addAll(['Alta Qualidade (AAC)', 'Média Qualidade (AAC)']);
        }

        return MediaMetadata(
          id: video.id.value,
          title: video.title,
          author: video.author,
          thumbnailUrl: video.thumbnails.mediumResUrl,
          isPlaylist: false,
          duration: video.duration,
          playlistVideos: null,
          videoQualities: videoQualities.isNotEmpty ? videoQualities : ['720p', '360p'],
          audioQualities: audioQualities,
        );
      }
    } catch (e) {
      throw Exception('Falha ao obter metadados da mídia: $e');
    }
  }
}
