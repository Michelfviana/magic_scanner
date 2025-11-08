import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'presentation/screens/scan_screen.dart';
import 'presentation/screens/history_screen.dart';
import 'presentation/screens/result_screen.dart';
import 'presentation/screens/debug_screen.dart';
import 'data/datasources/local_data_source.dart';

void main() {
  // Inicializa o SQLite para desktop (Linux, Windows, macOS)
  LocalDataSource.initializeSqflite();

  runApp(const ProviderScope(child: MagicScannerApp()));
}

class MagicScannerApp extends StatelessWidget {
  const MagicScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Magic Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/scan',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return MainNavigation(child: child);
      },
      routes: [
        GoRoute(
          path: '/scan',
          builder: (context, state) => const ScanScreen(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) {
        final cardData = state.extra as Map<String, dynamic>?;
        return ResultScreen(cardData: cardData);
      },
    ),
    GoRoute(
      path: '/debug',
      builder: (context, state) => const DebugScreen(),
    ),
  ],
);

class MainNavigation extends StatelessWidget {
  final Widget child;

  const MainNavigation({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Escanear',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Histórico',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/scan')) return 0;
    if (location.startsWith('/history')) return 1;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/scan');
        break;
      case 1:
        context.go('/history');
        break;
    }
  }
}
