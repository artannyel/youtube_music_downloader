import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/explore/presentation/pages/explore_page.dart';
import '../../features/download_setup/presentation/pages/download_setup_page.dart';
import '../../features/downloads_history/presentation/pages/downloads_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/media_player/presentation/pages/media_player_page.dart';
import '../../features/media_player/presentation/pages/playlist_details_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

class AppRouter {
  static GoRouter get router {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/explore',
      routes: [
        // ShellRoute para a navegação por Abas (Bottom Navigation Bar)
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) {
            return AppShell(child: child);
          },
          routes: [
            GoRoute(
              path: '/explore',
              builder: (context, state) => const ExplorePage(),
            ),
            GoRoute(
              path: '/downloads',
              builder: (context, state) => const DownloadsPage(),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
        
        // Rotas de Tela Cheia (Fora da barra de navegação)
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/download-setup',
          builder: (context, state) {
            final url = state.extra as String?;
            return DownloadSetupPage(initialUrl: url ?? '');
          },
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/player',
          builder: (context, state) => const MediaPlayerPage(),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/playlist',
          builder: (context, state) {
            final playlistId = state.extra as String?;
            return PlaylistDetailsPage(playlistId: playlistId ?? '');
          },
        ),
      ],
    );
  }
}

// Widget da Estrutura de Navegação Geral (Shell)
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/explore')) return 0;
    if (location.startsWith('/downloads')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/explore');
        break;
      case 1:
        GoRouter.of(context).go('/downloads');
        break;
      case 2:
        GoRouter.of(context).go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(Icons.download_for_offline_outlined),
            selectedIcon: Icon(Icons.download_for_offline),
            label: 'Downloads',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
