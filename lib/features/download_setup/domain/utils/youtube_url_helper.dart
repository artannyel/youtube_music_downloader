class YoutubeUrlHelper {
  // Regex para identificar IDs de vídeo do YouTube (11 caracteres alfanuméricos, incluindo - e _)
  static final RegExp _videoRegex = RegExp(
    r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/|youtube\.com\/shorts\/)([^"&?\/\s]{11})',
    caseSensitive: false,
  );

  // Regex para identificar IDs de playlist do YouTube (tipicamente começam com PL e têm 18 ou 34 caracteres)
  static final RegExp _playlistRegex = RegExp(
    r'[?&]list=([^#\&\?]+)',
    caseSensitive: false,
  );

  // Verifica se a string inserida é uma URL ou ID do YouTube
  static bool isValidYoutubeInput(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;
    
    // Se for um ID de vídeo puro (11 caracteres)
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(trimmed)) return true;
    
    // Se for um ID de playlist puro (PL...)
    if (RegExp(r'^PL[a-zA-Z0-9_-]+$').hasMatch(trimmed)) return true;

    // Se contiver algum dos domínios do YouTube
    final lower = trimmed.toLowerCase();
    if (lower.contains('youtube.com') || lower.contains('youtu.be') || lower.contains('youtube-nocookie.com')) {
      return _videoRegex.hasMatch(trimmed) || _playlistRegex.hasMatch(trimmed);
    }
    
    return false;
  }

  // Extrai o ID do vídeo a partir de uma URL ou ID bruto
  static String? extractVideoId(String input) {
    final trimmed = input.trim();
    
    // Verifica se já é um ID de vídeo bruto
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(trimmed)) {
      return trimmed;
    }

    final match = _videoRegex.firstMatch(trimmed);
    return match?.group(1);
  }

  // Extrai o ID da playlist a partir de uma URL ou ID bruto
  static String? extractPlaylistId(String input) {
    final trimmed = input.trim();
    
    // Verifica se já é um ID de playlist bruto (PL...)
    if (RegExp(r'^PL[a-zA-Z0-9_-]+$').hasMatch(trimmed)) {
      return trimmed;
    }

    final match = _playlistRegex.firstMatch(trimmed);
    return match?.group(1);
  }

  // Converte URLs do YouTube Music para URLs clássicas do YouTube
  static String convertMusicToNormalUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.toLowerCase().contains('music.youtube.com')) {
      return trimmed.replaceAll('music.youtube.com', 'youtube.com');
    }
    return trimmed;
  }

  // Identifica se a URL aponta para uma Playlist
  static bool isPlaylist(String input) {
    final trimmed = input.trim();
    // Se for ID puro de playlist
    if (RegExp(r'^PL[a-zA-Z0-9_-]+$').hasMatch(trimmed)) {
      return true;
    }
    // Se a URL contiver o parâmetro 'list='
    return trimmed.toLowerCase().contains('list=') && _playlistRegex.hasMatch(trimmed);
  }

  // Faz o parse de múltiplos links inseridos em lote
  static List<String> parseMultipleUrls(String input) {
    if (input.trim().isEmpty) return [];
    
    // Divide por quebras de linha, vírgulas ou ponto e vírgula
    final rawLines = input.split(RegExp(r'[\n,\;]'));
    
    final List<String> validUrls = [];
    for (var line in rawLines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isNotEmpty && isValidYoutubeInput(trimmedLine)) {
        // Converte imediatamente se for do YouTube Music para normal
        validUrls.add(convertMusicToNormalUrl(trimmedLine));
      }
    }
    
    return validUrls;
  }
}
