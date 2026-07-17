class YoutubeVideoResult {
  final String id;
  final String title;
  final String author;
  final Duration? duration;
  final String thumbnailUrl;
  final int? viewCount;
  final bool isPlaylist;
  final int? playlistVideoCount;

  const YoutubeVideoResult({
    required this.id,
    required this.title,
    required this.author,
    this.duration,
    required this.thumbnailUrl,
    this.viewCount,
    this.isPlaylist = false,
    this.playlistVideoCount,
  });

  // Métodos úteis auxiliares de comparação e exibição
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YoutubeVideoResult &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'YoutubeVideoResult(id: $id, title: $title, author: $author)';
  }
}
