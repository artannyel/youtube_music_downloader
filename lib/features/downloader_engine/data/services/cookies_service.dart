import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// Serviço responsável por gerenciar o caminho do arquivo de cookies
/// para autenticação em vídeos restritos do YouTube.
///
/// O caminho do arquivo `cookies.txt` (formato Netscape) é persistido no
/// [SharedPreferences] e validado antes de ser injetado nas requisições
/// de download via flag `--cookies` do yt-dlp.
class CookiesService {
  static const String _cookiesPathKey = 'cookies_file_path';

  /// Salva o caminho do arquivo de cookies no SharedPreferences.
  static Future<void> saveCookiesPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cookiesPathKey, path);
  }

  /// Remove o caminho do arquivo de cookies do SharedPreferences.
  static Future<void> clearCookiesPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cookiesPathKey);
  }

  /// Retorna o caminho do arquivo de cookies salvo, ou `null` se não configurado.
  static Future<String?> getSavedCookiesPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cookiesPathKey);
  }

  /// Retorna o caminho do arquivo de cookies **somente** se ele existir
  /// no sistema de arquivos. Retorna `null` caso contrário.
  ///
  /// Deve ser chamado antes de iniciar um download para determinar se
  /// o argumento `--cookies` deve ser injetado no [DownloadRequest].
  static Future<String?> getValidCookiesPath() async {
    final savedPath = await getSavedCookiesPath();
    if (savedPath == null || savedPath.isEmpty) return null;

    final file = File(savedPath);
    if (await file.exists()) {
      return savedPath;
    }

    return null;
  }
}
