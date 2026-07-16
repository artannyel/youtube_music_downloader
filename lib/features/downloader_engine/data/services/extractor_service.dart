import 'package:extractor/extractor.dart';
import 'package:flutter/foundation.dart';

/// Serviço singleton responsável pela inicialização e acesso à instância
/// do YoutubeDLFlutter (pacote extractor).
///
/// Deve ser inicializado uma única vez no `main.dart` antes do `runApp`.
class ExtractorService {
  static final YoutubeDLFlutter _instance = YoutubeDLFlutter.instance;
  static bool _isInitialized = false;

  /// Retorna a instância do YoutubeDLFlutter.
  /// Lança um [StateError] se o serviço não foi inicializado.
  static YoutubeDLFlutter get instance {
    if (!_isInitialized) {
      throw StateError(
        'ExtractorService não foi inicializado. Chame initialize() no main.dart.',
      );
    }
    return _instance;
  }

  /// Indica se o serviço foi inicializado com sucesso.
  static bool get isInitialized => _isInitialized;

  /// Inicializa o extractor com suporte a FFmpeg e Aria2c.
  ///
  /// FFmpeg é necessário para merge de streams de vídeo+áudio e
  /// embedding de thumbnails. Aria2c acelera downloads com múltiplas conexões.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    final result = await _instance.initialize(
      enableFFmpeg: true,
      enableAria2c: false,
    );

    if (result.success) {
      _isInitialized = true;
      debugPrint('[ExtractorService] Inicializado com sucesso.');
    } else {
      debugPrint(
        '[ExtractorService] Falha ao inicializar: ${result.errorMessage}',
      );
      throw Exception(
        'Falha ao inicializar o motor de download: ${result.errorMessage}',
      );
    }
  }

  /// Atualiza o binário do yt-dlp para a versão mais recente.
  static Future<UpdateResult> update() async {
    return await _instance.updateYoutubeDL();
  }
}
