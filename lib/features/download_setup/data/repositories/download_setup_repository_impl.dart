import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_explode;
import '../../domain/entities/media_metadata.dart';
import '../../domain/repositories/download_setup_repository.dart';
import '../../domain/utils/youtube_url_helper.dart';
import '../../../../core/utils/custom_playlist_helper.dart';
import '../../../explore/domain/entities/youtube_video_result.dart';
import '../../../../features/downloader_engine/data/services/extractor_service.dart';

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

        String playlistTitle = 'Playlist';
        String playlistAuthor = 'YouTube Playlist';
        String playlistIdValue = playlistId;

        try {
          final playlist = await _yt.playlists.get(playlistId);
          playlistTitle = playlist.title;
          playlistAuthor = playlist.author.isNotEmpty ? playlist.author : 'YouTube Playlist';
          playlistIdValue = playlist.id.value;
        } catch (e) {
          debugPrint('[DownloadSetupRepository] Falha ao obter detalhes da playlist pelo package (rate limit): $e');
        }

        // Usa o helper customizado que suporta o novo formato lockupViewModel
        // retornado pelo YouTube que o package não parseia ainda.
        final List<yt_explode.Video> videoList =
            await CustomPlaylistHelper.getPlaylistVideos(playlistId);

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
          id: playlistIdValue,
          title: playlistTitle,
          author: playlistAuthor,
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

        yt_explode.Video? video;
        yt_explode.StreamManifest? manifest;
        bool useYtdlFallback = false;

        try {
          video = await _yt.videos.get(videoId);
          manifest = await _yt.videos.streams.getManifest(videoId);
        } catch (e) {
          useYtdlFallback = true;
          debugPrint('[DownloadSetupRepository] Fallback para yt-dlp devido ao rate-limit: $e');
        }

        if (useYtdlFallback) {
          final info = await ExtractorService.instance.getVideoInfo(normalizedUrl);

          final uniqueVideoQualities = <String>{};
          final uniqueAudioQualities = <String>{};

          if (info.formats != null) {
            for (final f in info.formats!) {
              if (f == null) continue;
              if (f.height != null && f.height! > 0) {
                uniqueVideoQualities.add('${f.height}p');
              }
              if (f.acodec != null &&
                  f.acodec != 'none' &&
                  (f.vcodec == 'none' || f.vcodec == null)) {
                final kbps = f.tbr != null ? f.tbr!.round() : 128;
                if (kbps >= 120) {
                  uniqueAudioQualities.add('Alta Qualidade ($kbps Kbps)');
                } else {
                  uniqueAudioQualities.add('Média Qualidade ($kbps Kbps)');
                }
              }
            }
          }

          final videoQualities = uniqueVideoQualities.toList()
            ..sort((a, b) {
              final aVal = int.tryParse(RegExp(r'\d+').firstMatch(a)?.group(0) ?? '0') ?? 0;
              final bVal = int.tryParse(RegExp(r'\d+').firstMatch(b)?.group(0) ?? '0') ?? 0;
              return bVal.compareTo(aVal);
            });

          final audioQualities = uniqueAudioQualities.toList()
            ..sort((a, b) {
              final aVal = int.tryParse(RegExp(r'\d+').firstMatch(a)?.group(0) ?? '0') ?? 0;
              final bVal = int.tryParse(RegExp(r'\d+').firstMatch(b)?.group(0) ?? '0') ?? 0;
              return bVal.compareTo(aVal);
            });

          if (audioQualities.isEmpty) {
            audioQualities.addAll(['Alta Qualidade (AAC)', 'Média Qualidade (AAC)']);
          }

          return MediaMetadata(
            id: info.id ?? videoId,
            title: info.title ?? 'Vídeo do YouTube',
            author: info.uploader ?? 'Desconhecido',
            thumbnailUrl: 'https://img.youtube.com/vi/${info.id ?? videoId}/hqdefault.jpg',
            isPlaylist: false,
            duration: null,
            playlistVideos: null,
            videoQualities: videoQualities.isNotEmpty ? videoQualities : ['720p', '360p'],
            audioQualities: audioQualities,
          );
        } else {
          // Fluxo normal usando youtube_explode
          final uniqueVideoQualities = <String>{};
          for (var stream in manifest!.videoOnly) {
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

          final videoQualities = uniqueVideoQualities.toList()
            ..sort((a, b) {
              final aVal = int.tryParse(RegExp(r'\d+').firstMatch(a)?.group(0) ?? '0') ?? 0;
              final bVal = int.tryParse(RegExp(r'\d+').firstMatch(b)?.group(0) ?? '0') ?? 0;
              return bVal.compareTo(aVal);
            });

          final uniqueAudioQualities = <String>{};
          for (var stream in manifest.audioOnly) {
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
              return bVal.compareTo(aVal);
            });

          if (audioQualities.isEmpty) {
            audioQualities.addAll(['Alta Qualidade (AAC)', 'Média Qualidade (AAC)']);
          }

          return MediaMetadata(
            id: video!.id.value,
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
      }
    } catch (e) {
      throw Exception('Falha ao obter metadados da mídia: $e');
    }
  }
}
