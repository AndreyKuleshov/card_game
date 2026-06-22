import 'package:flutter/material.dart';
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
      home: const WorldMapScreen(),
    );
  }
}
