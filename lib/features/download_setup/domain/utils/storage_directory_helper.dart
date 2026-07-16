import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StorageDirectoryHelper {
  /// Retorna a pasta padrão de Downloads do dispositivo.
  static Future<String> getDownloadsRootPath() async {
    if (Platform.isAndroid) {
      final androidDownloadDir = Directory('/storage/emulated/0/Download');
      if (await androidDownloadDir.exists()) {
        return androidDownloadDir.path;
      }
      final externalDir = await getExternalStorageDirectory();
      return externalDir?.path ?? '/storage/emulated/0/Download';
    } else {
      final downloadsDir = await getDownloadsDirectory();
      return downloadsDir?.path ?? Directory.current.path;
    }
  }

  /// Retorna o caminho completo de destino para o download.
  static Future<String> getTargetDirectoryPath({
    required String subfolder,
    required bool isAudio,
  }) async {
    final root = await getDownloadsRootPath();
    final mediaDir = isAudio ? 'musicas' : 'videos';
    final cleanedSubfolder = subfolder.trim();
    
    if (cleanedSubfolder.isEmpty) {
      return '$root/$mediaDir';
    }
    return '$root/$mediaDir/$cleanedSubfolder';
  }

  /// Verifica se o subdiretório de salvamento já existe localmente.
  static Future<bool> doesSubfolderExist({
    required String subfolder,
    required bool isAudio,
  }) async {
    final cleanedSubfolder = subfolder.trim();
    if (cleanedSubfolder.isEmpty) return false;
    
    final path = await getTargetDirectoryPath(
      subfolder: cleanedSubfolder,
      isAudio: isAudio,
    );
    return Directory(path).exists();
  }
}
