import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../download_setup/domain/utils/storage_directory_helper.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const String _cookiesPathKey = 'cookies_file_path';

  @override
  Future<void> saveCookiesPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cookiesPathKey, path);
  }

  @override
  Future<void> clearCookiesPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cookiesPathKey);
  }

  @override
  Future<String?> getCookiesPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cookiesPathKey);
  }

  @override
  Future<String> getDefaultDownloadDirectory() async {
    return StorageDirectoryHelper.getDownloadsRootPath();
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl();
});
