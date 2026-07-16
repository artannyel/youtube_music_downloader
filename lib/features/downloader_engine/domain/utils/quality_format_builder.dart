/// Utilitário para construir format strings do yt-dlp com fallback automático
/// de qualidade.
///
/// Ao invés de implementar um QualityMatcher manual, delegamos o fallback
/// para o próprio yt-dlp usando suas format strings nativas, que são mais
/// confiáveis e lidam com edge cases automaticamente.
///
/// Exemplo: Se o usuário pede `1080p` mas o vídeo só tem `720p`, o yt-dlp
/// seleciona automaticamente `720p` com a format string
/// `bestvideo[height<=1080]+bestaudio/best[height<=1080]`.
class QualityFormatBuilder {
  /// Mapeamento de labels de qualidade de vídeo para altura em pixels.
  static const Map<String, int> _videoHeightMap = {
    '4320p': 4320,
    '2880p': 2880,
    '2160p': 2160,
    '1440p': 1440,
    '1080p': 1080,
    '720p': 720,
    '480p': 480,
    '360p': 360,
    '240p': 240,
    '144p': 144,
  };

  /// Constrói a format string para download de **vídeo** com fallback.
  ///
  /// Ex: Se [qualityLabel] = '1080p', retorna:
  ///   `bestvideo[height<=1080]+bestaudio/best[height<=1080]`
  ///
  /// Isso instrui o yt-dlp a buscar o melhor vídeo com altura ≤ 1080p.
  /// Se não existir 1080p, ele automaticamente pega a próxima menor
  /// disponível (720p, 480p, etc).
  static String buildVideoFormat(String qualityLabel) {
    final height = _videoHeightMap[qualityLabel];

    if (height == null) {
      // Fallback: qualidade desconhecida, usar o melhor disponível
      return 'bestvideo+bestaudio/best';
    }

    return 'bestvideo[height<=$height]+bestaudio/best[height<=$height]';
  }

  /// Constrói a format string para download de **áudio**.
  ///
  /// Para áudio, o yt-dlp já seleciona o melhor stream disponível.
  /// Retorna sempre `bestaudio/best` pois a qualidade final é controlada
  /// pelo parâmetro [audioQuality] do DownloadRequest (0 = melhor).
  static String buildAudioFormat() {
    return 'bestaudio/best';
  }

  /// Mapeia a label de qualidade de áudio para o valor numérico
  /// do parâmetro `audioQuality` do yt-dlp (0 = melhor, 9 = pior).
  ///
  /// Labels que contêm "Alta" retornam 0 (melhor qualidade).
  /// Labels que contêm "Média" retornam 5 (qualidade média).
  /// Caso contrário, retorna 0 como fallback seguro.
  static int mapAudioQuality(String qualityLabel) {
    final lower = qualityLabel.toLowerCase();
    if (lower.contains('alta')) return 0;
    if (lower.contains('média') || lower.contains('media')) return 5;
    return 0; // Fallback para melhor qualidade
  }
}
