import 'dart:collection';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_explode;
import 'package:youtube_music_downloader/features/download_setup/data/repositories/download_setup_repository_impl.dart';
import 'download_setup_repository_impl_test.mocks.dart';

// Gera as classes mockadas com Mockito e build_runner
@GenerateNiceMocks([
  MockSpec<yt_explode.YoutubeExplode>(),
  MockSpec<yt_explode.VideoClient>(),
  MockSpec<yt_explode.StreamClient>(),
  MockSpec<yt_explode.PlaylistClient>(),
  MockSpec<yt_explode.Video>(),
  MockSpec<yt_explode.Playlist>(),
  MockSpec<yt_explode.StreamManifest>(),
  MockSpec<yt_explode.ThumbnailSet>(),
  MockSpec<yt_explode.VideoOnlyStreamInfo>(),
  MockSpec<yt_explode.MuxedStreamInfo>(),
  MockSpec<yt_explode.AudioOnlyStreamInfo>(),
])
class DownloadSetupMocks {}

void main() {
  group('DownloadSetupRepositoryImpl', () {
    late MockYoutubeExplode mockYoutubeExplode;
    late MockVideoClient mockVideosClient;
    late MockStreamClient mockStreamsClient;
    late MockPlaylistClient mockPlaylistsClient;
    late DownloadSetupRepositoryImpl repository;

    setUp(() {
      mockYoutubeExplode = MockYoutubeExplode();
      mockVideosClient = MockVideoClient();
      mockStreamsClient = MockStreamClient();
      mockPlaylistsClient = MockPlaylistClient();

      // Configura os sub-clients do YoutubeExplode
      when(mockYoutubeExplode.videos).thenReturn(mockVideosClient);
      when(mockVideosClient.streams).thenReturn(mockStreamsClient);
      when(mockYoutubeExplode.playlists).thenReturn(mockPlaylistsClient);

      repository = DownloadSetupRepositoryImpl(mockYoutubeExplode);
    });

    test('should fetch and parse single video metadata correctly', () async {
      const videoId = 'dQw4w9WgXcQ';
      const url = 'https://www.youtube.com/watch?v=$videoId';

      final mockVideo = MockVideo();
      final mockThumbnailSet = MockThumbnailSet();
      final mockStreamManifest = MockStreamManifest();

      // Configura o mock do VideoId e informações
      when(mockVideo.id).thenReturn(yt_explode.VideoId(videoId));
      when(mockVideo.title).thenReturn('Never Gonna Give You Up');
      when(mockVideo.author).thenReturn('Rick Astley');
      when(mockVideo.duration).thenReturn(const Duration(minutes: 3, seconds: 32));
      when(mockVideo.thumbnails).thenReturn(mockThumbnailSet);
      when(mockThumbnailSet.mediumResUrl).thenReturn('https://img.youtube.com/vi/$videoId/mqdefault.jpg');

      // Configura streams simulando resoluções e bitrates
      final mockVideo1080 = MockVideoOnlyStreamInfo();
      when(mockVideo1080.videoQuality).thenReturn(yt_explode.VideoQuality.high1080);

      final mockVideo720 = MockVideoOnlyStreamInfo();
      when(mockVideo720.videoQuality).thenReturn(yt_explode.VideoQuality.high720);

      final mockMuxed360 = MockMuxedStreamInfo();
      when(mockMuxed360.videoQuality).thenReturn(yt_explode.VideoQuality.medium360);

      final mockAudioOpus = MockAudioOnlyStreamInfo();
      when(mockAudioOpus.bitrate).thenReturn(yt_explode.Bitrate(160000)); // ~160 Kbps

      final mockAudioAac = MockAudioOnlyStreamInfo();
      when(mockAudioAac.bitrate).thenReturn(yt_explode.Bitrate(96000)); // ~96 Kbps

      when(mockStreamManifest.videoOnly).thenReturn(UnmodifiableListView([mockVideo1080, mockVideo720]));
      when(mockStreamManifest.muxed).thenReturn(UnmodifiableListView([mockMuxed360]));
      when(mockStreamManifest.audioOnly).thenReturn(UnmodifiableListView([mockAudioOpus, mockAudioAac]));

      // Configura os comportamentos dos clients
      when(mockVideosClient.get(any)).thenAnswer((_) async => mockVideo);
      when(mockStreamsClient.getManifest(any)).thenAnswer((_) async => mockStreamManifest);

      // Executa o repositório
      final metadata = await repository.fetchMetadata(url);

      // Asserções
      expect(metadata.id, equals(videoId));
      expect(metadata.title, equals('Never Gonna Give You Up'));
      expect(metadata.author, equals('Rick Astley'));
      expect(metadata.thumbnailUrl, equals('https://img.youtube.com/vi/$videoId/mqdefault.jpg'));
      expect(metadata.isPlaylist, isFalse);
      expect(metadata.duration, equals(const Duration(minutes: 3, seconds: 32)));
      expect(metadata.playlistVideos, isNull);
      
      // Valida ordenação das resoluções (1080p -> 720p -> 360p)
      expect(metadata.videoQualities, equals(['1080p', '720p', '360p']));
      
      // Valida bitrate classificado (160 Kbps -> Alta Qualidade, 96 Kbps -> Média Qualidade)
      expect(metadata.audioQualities, contains('Alta Qualidade (160 Kbps)'));
      expect(metadata.audioQualities, contains('Média Qualidade (96 Kbps)'));

      verify(mockVideosClient.get(videoId)).called(1);
      verify(mockStreamsClient.getManifest(videoId)).called(1);
    });

    test('should fetch and parse playlist metadata correctly', () async {
      const playlistId = 'PL3KnTfyhrIlcudeMemKd6rZFGDWyK23vx';
      const url = 'https://www.youtube.com/playlist?list=$playlistId';

      final mockPlaylist = MockPlaylist();
      final mockVideoInPlaylist = MockVideo();
      final mockThumbnailSet = MockThumbnailSet();

      // Configura a Playlist mockada
      when(mockPlaylist.id).thenReturn(yt_explode.PlaylistId(playlistId));
      when(mockPlaylist.title).thenReturn('My Playlist');
      when(mockPlaylist.author).thenReturn('My Channel');

      // Configura o vídeo dentro da playlist
      when(mockVideoInPlaylist.id).thenReturn(yt_explode.VideoId('ABC123XYZ78'));
      when(mockVideoInPlaylist.title).thenReturn('Playlist Video Title');
      when(mockVideoInPlaylist.author).thenReturn('Author Name');
      when(mockVideoInPlaylist.duration).thenReturn(const Duration(minutes: 4));
      when(mockVideoInPlaylist.thumbnails).thenReturn(mockThumbnailSet);
      when(mockThumbnailSet.mediumResUrl).thenReturn('https://img.youtube.com/vi/ABC123XYZ78/mqdefault.jpg');
      when(mockVideoInPlaylist.engagement).thenReturn(yt_explode.Engagement(1234, 100, 10));

      // Configura os retornos de chamada
      when(mockPlaylistsClient.get(any)).thenAnswer((_) async => mockPlaylist);
      when(mockPlaylistsClient.getVideos(any)).thenAnswer(
        (_) => Stream.fromIterable([mockVideoInPlaylist]),
      );

      // Executa o repositório
      final metadata = await repository.fetchMetadata(url);

      // Asserções
      expect(metadata.id, equals(playlistId));
      expect(metadata.title, equals('My Playlist'));
      expect(metadata.author, equals('My Channel'));
      expect(metadata.isPlaylist, isTrue);
      expect(metadata.duration, isNull);
      
      expect(metadata.playlistVideos, isNotNull);
      expect(metadata.playlistVideos!.length, equals(1));
      expect(metadata.playlistVideos!.first.id, equals('ABC123XYZ78'));
      expect(metadata.playlistVideos!.first.title, equals('Playlist Video Title'));
      
      expect(metadata.videoQualities, equals(['1080p', '720p', '480p', '360p']));

      verify(mockPlaylistsClient.get(playlistId)).called(1);
      verify(mockPlaylistsClient.getVideos(yt_explode.PlaylistId(playlistId))).called(1);
    });
  });
}
