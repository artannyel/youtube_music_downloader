abstract class SettingsRepository {
  /// Salva o caminho do arquivo de cookies.
  Future<void> saveCookiesPath(String path);

  /// Remove o caminho do arquivo de cookies configurado.
  Future<void> clearCookiesPath();

  /// Retorna o caminho do arquivo de cookies configurado, ou null se não houver.
  Future<String?> getCookiesPath();

  /// Retorna o caminho da pasta padrão de downloads.
  Future<String> getDefaultDownloadDirectory();
}
