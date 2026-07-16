import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:youtube_music_downloader/features/settings/domain/repositories/settings_repository.dart';
import 'package:youtube_music_downloader/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:youtube_music_downloader/features/settings/presentation/providers/settings_provider.dart';

import 'settings_provider_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<SettingsRepository>(),
])
class SettingsMocks {}

void main() {
  late MockSettingsRepository mockRepository;
  late ProviderContainer container;
  late SettingsNotifier notifier;

  setUp(() {
    mockRepository = MockSettingsRepository();

    // Default stubbing for initial loadSettings call in constructor
    when(mockRepository.getCookiesPath()).thenAnswer((_) async => null);
    when(mockRepository.getDefaultDownloadDirectory()).thenAnswer((_) async => '/downloads');

    container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );

    notifier = container.read(settingsStateProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  group('SettingsNotifier Tests', () {
    test('should load default settings correctly on initialize', () async {
      await notifier.loadSettings();

      final state = container.read(settingsStateProvider);
      expect(state.cookiesPath, isNull);
      expect(state.downloadDirectory, equals('/downloads'));
      expect(state.isLoading, isFalse);

      verify(mockRepository.getCookiesPath()).called(greaterThanOrEqualTo(1));
      verify(mockRepository.getDefaultDownloadDirectory()).called(greaterThanOrEqualTo(1));
    });

    test('should update cookies path and save to repository', () async {
      const path = '/path/to/cookies.txt';

      await notifier.updateCookiesPath(path);

      final state = container.read(settingsStateProvider);
      expect(state.cookiesPath, equals(path));
      verify(mockRepository.saveCookiesPath(path)).called(1);
    });

    test('should remove cookies path and clear in repository', () async {
      await notifier.removeCookies();

      final state = container.read(settingsStateProvider);
      expect(state.cookiesPath, isNull);
      verify(mockRepository.clearCookiesPath()).called(1);
    });
  });
}
