import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/isar_service.dart';
import 'core/router/router.dart';
import 'core/theme/theme.dart';
import 'features/downloader_engine/data/services/extractor_service.dart';
import 'features/downloader_engine/presentation/providers/download_queue_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicialização do Banco de Dados Local Isar
  await IsarService.initialize();

  // Inicialização do Motor de Downloads (yt-dlp + FFmpeg + Aria2c)
  await ExtractorService.initialize();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'YouTube Downloader',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
      builder: (context, child) {
        // Instancia o downloadQueueProvider logo na primeira renderização
        // para que ele retome downloads interrompidos antes de qualquer
        // navegação do usuário.
        return Consumer(
          builder: (context, ref, _) {
            ref.read(downloadQueueProvider);
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}
