import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_music_downloader/features/download_setup/domain/utils/youtube_url_helper.dart';

void main() {
  group('YoutubeUrlHelper', () {
    group('isValidYoutubeInput', () {
      test('should return true for valid YouTube URLs', () {
        expect(YoutubeUrlHelper.isValidYoutubeInput('https://www.youtube.com/watch?v=dQw4w9WgXcQ'), isTrue);
        expect(YoutubeUrlHelper.isValidYoutubeInput('https://youtu.be/dQw4w9WgXcQ'), isTrue);
        expect(YoutubeUrlHelper.isValidYoutubeInput('https://music.youtube.com/watch?v=dQw4w9WgXcQ'), isTrue);
        expect(YoutubeUrlHelper.isValidYoutubeInput('https://www.youtube.com/shorts/dQw4w9WgXcQ'), isTrue);
      });

      test('should return true for valid YouTube Playlists', () {
        expect(YoutubeUrlHelper.isValidYoutubeInput('https://www.youtube.com/playlist?list=PL3KnTfyhrIlcudeMemKd6rZFGDWyK23vx'), isTrue);
        expect(YoutubeUrlHelper.isValidYoutubeInput('https://music.youtube.com/playlist?list=PL3KnTfyhrIlcudeMemKd6rZFGDWyK23vx'), isTrue);
      });

      test('should return true for raw IDs', () {
        expect(YoutubeUrlHelper.isValidYoutubeInput('dQw4w9WgXcQ'), isTrue);
        expect(YoutubeUrlHelper.isValidYoutubeInput('PL3KnTfyhrIlcudeMemKd6rZFGDWyK23vx'), isTrue);
      });

      test('should return false for invalid inputs', () {
        expect(YoutubeUrlHelper.isValidYoutubeInput(''), isFalse);
        expect(YoutubeUrlHelper.isValidYoutubeInput('   '), isFalse);
        expect(YoutubeUrlHelper.isValidYoutubeInput('https://google.com'), isFalse);
        expect(YoutubeUrlHelper.isValidYoutubeInput('not-an-id'), isFalse);
      });
    });

    group('extractVideoId', () {
      test('should extract 11-char ID from various formats', () {
        expect(YoutubeUrlHelper.extractVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'), equals('dQw4w9WgXcQ'));
        expect(YoutubeUrlHelper.extractVideoId('https://youtu.be/dQw4w9WgXcQ'), equals('dQw4w9WgXcQ'));
        expect(YoutubeUrlHelper.extractVideoId('https://music.youtube.com/watch?v=dQw4w9WgXcQ'), equals('dQw4w9WgXcQ'));
        expect(YoutubeUrlHelper.extractVideoId('https://www.youtube.com/shorts/dQw4w9WgXcQ'), equals('dQw4w9WgXcQ'));
        expect(YoutubeUrlHelper.extractVideoId('dQw4w9WgXcQ'), equals('dQw4w9WgXcQ'));
      });

      test('should return null for invalid video URLs or playlist URLs without video parameter', () {
        expect(YoutubeUrlHelper.extractVideoId('https://www.youtube.com/playlist?list=PL3KnTfyhrIlcudeMemKd6rZFGDWyK23vx'), isNull);
        expect(YoutubeUrlHelper.extractVideoId('https://google.com'), isNull);
      });
    });

    group('extractPlaylistId', () {
      test('should extract playlist ID from playlist URL', () {
        expect(YoutubeUrlHelper.extractPlaylistId('https://www.youtube.com/playlist?list=PL3KnTfyhrIlcudeMemKd6rZFGDWyK23vx'), equals('PL3KnTfyhrIlcudeMemKd6rZFGDWyK23vx'));
        expect(YoutubeUrlHelper.extractPlaylistId('https://music.youtube.com/playlist?list=PL3KnTfyhrIlcudeMemKd6rZFGDWyK23vx'), equals('PL3KnTfyhrIlcudeMemKd6rZFGDWyK23vx'));
        expect(YoutubeUrlHelper.extractPlaylistId('PL3KnTfyhrIlcudeMemKd6rZFGDWyK23vx'), equals('PL3KnTfyhrIlcudeMemKd6rZFGDWyK23vx'));
      });

      test('should return null for non-playlist inputs', () {
        expect(YoutubeUrlHelper.extractPlaylistId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'), isNull);
        expect(YoutubeUrlHelper.extractPlaylistId('dQw4w9WgXcQ'), isNull);
      });
    });

    group('convertMusicToNormalUrl', () {
      test('should convert YouTube Music domain to standard YouTube domain', () {
        expect(YoutubeUrlHelper.convertMusicToNormalUrl('https://music.youtube.com/watch?v=dQw4w9WgXcQ'), equals('https://youtube.com/watch?v=dQw4w9WgXcQ'));
        expect(YoutubeUrlHelper.convertMusicToNormalUrl('https://music.youtube.com/playlist?list=PL3Kn'), equals('https://youtube.com/playlist?list=PL3Kn'));
      });

      test('should keep standard YouTube URLs unchanged', () {
        expect(YoutubeUrlHelper.convertMusicToNormalUrl('https://www.youtube.com/watch?v=dQw4w9WgXcQ'), equals('https://www.youtube.com/watch?v=dQw4w9WgXcQ'));
      });
    });

    group('isPlaylist', () {
      test('should return true for playlists', () {
        expect(YoutubeUrlHelper.isPlaylist('https://www.youtube.com/playlist?list=PL3KnT'), isTrue);
        expect(YoutubeUrlHelper.isPlaylist('PL3KnT'), isTrue);
      });

      test('should return false for single videos', () {
        expect(YoutubeUrlHelper.isPlaylist('https://www.youtube.com/watch?v=dQw4w9WgXcQ'), isFalse);
        expect(YoutubeUrlHelper.isPlaylist('dQw4w9WgXcQ'), isFalse);
      });
    });

    group('parseMultipleUrls', () {
      test('should parse list of URLs split by comma or newlines and clean them', () {
        const input = 'https://music.youtube.com/watch?v=dQw4w9WgXcQ\nhttps://youtu.be/dQw4w9WgXcQ, dQw4w9WgXcQ; https://google.com';
        final results = YoutubeUrlHelper.parseMultipleUrls(input);
        expect(results.length, equals(3));
        expect(results[0], equals('https://youtube.com/watch?v=dQw4w9WgXcQ'));
        expect(results[1], equals('https://youtu.be/dQw4w9WgXcQ'));
        expect(results[2], equals('dQw4w9WgXcQ'));
      });
    });
  });
}
