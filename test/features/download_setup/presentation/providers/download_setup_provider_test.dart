import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:youtube_music_downloader/features/download_setup/domain/entities/media_metadata.dart';
import 'package:youtube_music_downloader/features/download_setup/domain/repositories/download_setup_repository.dart';
import 'package:youtube_music_downloader/features/download_setup/presentation/providers/download_setup_provider.dart';
import 'package:youtube_music_downloader/features/downloads_history/data/models/download_task.dart';
import 'download_setup_provider_test.mocks.dart';

// Fake de PathProviderPlatform para não falhar nas chamadas de diretórios
class FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String mockPath;

  FakePathProviderPlatform(this.mockPath);

  @override
  Future<String?> getDownloadsPath() async => mockPath;

  @override
  Future<String?> getExternalStoragePath() async => mockPath;
}

@GenerateNiceMocks([MockSpec<DownloadSetupRepository>()])
class DownloadSetupProviderMocks {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDownloadSetupRepository mockRepository;
  late DownloadSetupNotifier notifier;
  late Directory tempDir;
  late PathProviderPlatform originalPlatform;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('setup_provider_test_');
    originalPlatform = PathProviderPlatform.instance;
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);

    mockRepository = MockDownloadSetupRepository();
    notifier = DownloadSetupNotifier(mockRepository);
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPlatform;
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('DownloadSetupNotifier', () {
    const videoUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
    const mockMetadata = MediaMetadata(
      id: 'dQw4w9WgXcQ',
      title: 'Never Gonna Give You Up',
      author: 'Rick Astley',
      thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg',
      isPlaylist: false,
      duration: Duration(minutes: 3, seconds: 32),
      videoQualities: ['1080p', '720p', '360p'],
      audioQualities: ['Alta Qualidade (160 Kbps)', 'Média Qualidade (96 Kbps)'],
    );

    test('should load metadata and set state correctly', () async {
      when(mockRepository.fetchMetadata(videoUrl))
          .thenAnswer((_) async => mockMetadata);

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.metadata, isNull);

      final future = notifier.loadMetadata(videoUrl);

      // Deve estar carregando imediatamente
      expect(notifier.state.isLoading, isTrue);

      await future;

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.metadata, equals(mockMetadata));
      expect(notifier.state.selectedFormat, equals(DownloadType.video));
      expect(notifier.state.selectedQuality, equals('1080p'));
      expect(notifier.state.subfolder, isEmpty);
      expect(notifier.state.subfolderExists, isFalse);
    });

    test('should switch format and quality options correctly', () async {
      // 1. Carrega os metadados iniciais
      when(mockRepository.fetchMetadata(videoUrl))
          .thenAnswer((_) async => mockMetadata);
      await notifier.loadMetadata(videoUrl);

      expect(notifier.state.selectedFormat, equals(DownloadType.video));
      expect(notifier.state.selectedQuality, equals('1080p'));

      // 2. Muda para áudio
      await notifier.setFormat(DownloadType.audio);

      expect(notifier.state.selectedFormat, equals(DownloadType.audio));
      expect(notifier.state.selectedQuality, equals('Alta Qualidade (160 Kbps)'));

      // 3. Muda de volta para vídeo
      await notifier.setFormat(DownloadType.video);

      expect(notifier.state.selectedFormat, equals(DownloadType.video));
      expect(notifier.state.selectedQuality, equals('1080p'));
    });

    test('should update selected quality manually', () async {
      when(mockRepository.fetchMetadata(videoUrl))
          .thenAnswer((_) async => mockMetadata);
      await notifier.loadMetadata(videoUrl);

      notifier.setQuality('720p');
      expect(notifier.state.selectedQuality, equals('720p'));
    });

    test('should update subfolder and detect if folder exists', () async {
      when(mockRepository.fetchMetadata(videoUrl))
          .thenAnswer((_) async => mockMetadata);
      await notifier.loadMetadata(videoUrl);

      const subName = 'favorites';
      await notifier.setSubfolder(subName);

      expect(notifier.state.subfolder, equals(subName));
      expect(notifier.state.subfolderExists, isFalse);

      // Cria a pasta fisicamente na raiz temporária de testes
      final expectedPath = '${tempDir.path}/videos/$subName';
      await Directory(expectedPath).create(recursive: true);

      // Atualiza a subpasta para forçar a verificação de existência
      await notifier.setSubfolder(subName);

      expect(notifier.state.subfolderExists, isTrue);
    });
  });
}
