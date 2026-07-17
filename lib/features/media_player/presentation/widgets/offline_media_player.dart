import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import '../providers/player_provider.dart';

class OfflineMediaPlayer extends StatelessWidget {
  final PlaybackMediaType mediaType;
  final PlayerMediaItem item;
  final ChewieController? chewieController;

  const OfflineMediaPlayer({
    super.key,
    required this.mediaType,
    required this.item,
    this.chewieController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (mediaType == PlaybackMediaType.video) {
      if (chewieController == null) {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: chewieController!.videoPlayerController.value.aspectRatio,
          child: Chewie(controller: chewieController!),
        ),
      );
    } else {
      // Exibe uma capa/thumbnail premium do álbum com gradiente sutil
      return Container(
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                item.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  child: Icon(Icons.music_note_rounded, size: 100, color: theme.colorScheme.primary),
                ),
              ),
              // Overlay degradê escuro
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
