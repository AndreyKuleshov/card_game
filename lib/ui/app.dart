import 'package:flutter/material.dart';
import 'game_assets.dart';
import 'theme.dart';
import 'world_map_screen.dart';

class CardGameApp extends StatelessWidget {
  const CardGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Карточное Королевство',
      debugShowCheckedModeBanner: false,
      theme: GameColors.warmTheme(),
      home: const _AssetPreloader(),
    );
  }
}

/// Precaches all gameplay artwork before showing the game, so screens never
/// flash with half-loaded images. Shows a spinner until every image is ready
/// (a failed/missing image is skipped rather than blocking startup).
class _AssetPreloader extends StatefulWidget {
  const _AssetPreloader();

  @override
  State<_AssetPreloader> createState() => _AssetPreloaderState();
}

class _AssetPreloaderState extends State<_AssetPreloader> {
  bool _ready = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _preload();
  }

  Future<void> _preload() async {
    await Future.wait([
      for (final path in GameAssets.preload)
        precacheImage(AssetImage(path), context).catchError((_) {}),
    ]);
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return const WorldMapScreen();
    return const _SplashScreen();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: GameColors.backgroundStops,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🏰 Карточное Королевство',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFE65100),
                ),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(color: Color(0xFFF57C00)),
              SizedBox(height: 12),
              Text(
                'Загрузка…',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8D6E63),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
