import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:youtube_music_downloader/features/download_setup/domain/utils/storage_directory_helper.dart';

// Fake de PathProviderPlatform usando o Mixin padrão do Flutter
class FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String mockPath;

  FakePathProviderPlatform(this.mockPath);

  @override
  Future<String?> getDownloadsPath() async => mockPath;

  @override
  Future<String?> getExternalStoragePath() async => mockPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late PathProviderPlatform originalPlatform;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('storage_helper_test_');
    originalPlatform = PathProviderPlatform.instance;
    
    // Registra a nossa classe fake para o PathProvider
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
  });

  tearDown(() async {
    // Restaura a instância original
    PathProviderPlatform.instance = originalPlatform;

    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('StorageDirectoryHelper', () {
    test('should resolve target directory paths correctly', () async {
      final root = tempDir.path;

      final videoPathEmpty = await StorageDirectoryHelper.getTargetDirectoryPath(
        subfolder: '',
        isAudio: false,
      );
      expect(videoPathEmpty, equals('$root/videos'));

      final audioPathEmpty = await StorageDirectoryHelper.getTargetDirectoryPath(
        subfolder: '   ',
        isAudio: true,
      );
      expect(audioPathEmpty, equals('$root/musicas'));

      final videoPathSub = await StorageDirectoryHelper.getTargetDirectoryPath(
        subfolder: 'my_subfolder',
        isAudio: false,
      );
      expect(videoPathSub, equals('$root/videos/my_subfolder'));

      final audioPathSub = await StorageDirectoryHelper.getTargetDirectoryPath(
        subfolder: 'chill_mix',
        isAudio: true,
      );
      expect(audioPathSub, equals('$root/musicas/chill_mix'));
    });

    test('should return true if subfolder exists and false if not', () async {
      const subfolder = 'rock_classics';

      // 1. Não existe ainda
      final existsBefore = await StorageDirectoryHelper.doesSubfolderExist(
        subfolder: subfolder,
        isAudio: true,
      );
      expect(existsBefore, isFalse);

      // 2. Cria a pasta fisicamente no diretório temporário simulado
      final expectedPath = await StorageDirectoryHelper.getTargetDirectoryPath(
        subfolder: subfolder,
        isAudio: true,
      );
      await Directory(expectedPath).create(recursive: true);

      // 3. Agora deve existir
      final existsAfter = await StorageDirectoryHelper.doesSubfolderExist(
        subfolder: subfolder,
        isAudio: true,
      );
      expect(existsAfter, isTrue);
    });

    test('should return false for empty/blank subfolder existence check', () async {
      final existsEmpty = await StorageDirectoryHelper.doesSubfolderExist(
        subfolder: '',
        isAudio: false,
      );
      expect(existsEmpty, isFalse);
    });
  });
}
