import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../data/repositories/settings_repository_impl.dart';

class SettingsState {
  final String? cookiesPath;
  final String downloadDirectory;
  final bool isLoading;

  const SettingsState({
    this.cookiesPath,
    required this.downloadDirectory,
    required this.isLoading,
  });

  const SettingsState.initial()
      : cookiesPath = null,
        downloadDirectory = '',
        isLoading = false;

  SettingsState copyWith({
    String? cookiesPath,
    String? downloadDirectory,
    bool? isLoading,
    bool clearCookiesPath = false,
  }) {
    return SettingsState(
      cookiesPath: clearCookiesPath ? null : (cookiesPath ?? this.cookiesPath),
      downloadDirectory: downloadDirectory ?? this.downloadDirectory,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super(const SettingsState.initial()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true);
    final cookies = await _repository.getCookiesPath();
    final downloadDir = await _repository.getDefaultDownloadDirectory();
    state = SettingsState(
      cookiesPath: cookies,
      downloadDirectory: downloadDir,
      isLoading: false,
    );
  }

  Future<void> updateCookiesPath(String path) async {
    await _repository.saveCookiesPath(path);
    state = state.copyWith(cookiesPath: path);
  }

  Future<void> removeCookies() async {
    await _repository.clearCookiesPath();
    state = state.copyWith(clearCookiesPath: true);
  }
}

final settingsStateProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repository);
});
