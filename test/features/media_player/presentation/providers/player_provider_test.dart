import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:youtube_music_downloader/features/media_player/presentation/providers/player_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late PlayerNotifier notifier;

  setUp(() {
    // Stub de MethodChannel para just_audio e video_player para evitar crash no teste
    const MethodChannel justAudioChannel = MethodChannel('com.ryanheise.just_audio.methods');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(justAudioChannel, (MethodCall methodCall) async {
      if (methodCall.method == 'init') {
        final map = methodCall.arguments as Map;
        final id = map['id'] as String;
        final playerChannel = MethodChannel('com.ryanheise.just_audio.methods.$id');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(playerChannel, (MethodCall playerMethodCall) async {
          return {};
        });
      }
      return {};
    });

    const MethodChannel videoPlayerChannel = MethodChannel('flutter.io/videoPlayer');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(videoPlayerChannel, (MethodCall methodCall) async {
      return {};
    });

    container = ProviderContainer();
    notifier = container.read(playerProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  group('PlayerNotifier State Tests', () {
    test('should have correct initial state', () {
      final state = container.read(playerProvider);
      expect(state.status, equals(PlaybackStatus.idle));
      expect(state.currentItem, isNull);
      expect(state.queue, isEmpty);
      expect(state.currentQueueIndex, equals(-1));
      expect(state.position, equals(Duration.zero));
      expect(state.duration, equals(Duration.zero));
    });

    test('should correctly navigate empty queue', () async {
      await notifier.playNext();
      var state = container.read(playerProvider);
      expect(state.currentQueueIndex, equals(-1));

      await notifier.playPrevious();
      state = container.read(playerProvider);
      expect(state.currentQueueIndex, equals(-1));
    });

    test('should handle loadMedia setup parameters correctly', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/song.mp3')..createSync();

      final item1 = PlayerMediaItem(
        id: 'dQw4w9WgXcQ',
        title: 'Song 1',
        artist: 'Artist 1',
        thumbnailUrl: 'thumb1',
        url: 'url1',
        localPath: tempFile.path,
      );

      final item2 = PlayerMediaItem(
        id: '456',
        title: 'Song 2',
        artist: 'Artist 2',
        thumbnailUrl: 'thumb2',
        url: 'url2',
        localPath: tempFile.path,
      );

      final queue = [item1, item2];

      notifier.loadMedia(
        item1,
        source: PlaybackSource.offline,
        mediaType: PlaybackMediaType.audio,
        newQueue: queue,
      );

      // Permite que as etapas assíncronas iniciais rodem e atualizem o estado
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(playerProvider);
      expect(state.currentItem?.id, equals('dQw4w9WgXcQ'));
      expect(state.queue.length, equals(2));
      expect(state.currentQueueIndex, equals(0));

      tempDir.deleteSync(recursive: true);
    });
  });
}
