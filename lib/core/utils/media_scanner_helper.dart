import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MediaScannerHelper {
  static const _channel = MethodChannel('com.arttecsoftware.youtube_music_downloader/media_scanner');

  /// Escaneia um arquivo de mídia no Android para indexá-lo no MediaStore do sistema.
  /// Isso faz com que mídias recém-baixadas fiquem visíveis para outros aplicativos de galeria e tocadores de música.
  static Future<void> scanFile(String path) async {
    try {
      await _channel.invokeMethod('scanFile', {'path': path});
      debugPrint('[MediaScanner] Solicitado escaneamento para o arquivo: $path');
    } on PlatformException catch (e) {
      debugPrint('[MediaScanner] Erro na plataforma ao escanear: ${e.message}');
    } catch (e) {
      debugPrint('[MediaScanner] Erro ao escanear arquivo de mídia: $e');
    }
  }
}
