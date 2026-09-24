import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/audio_service.dart';
import 'ui/game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Immersive full screen
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize audio service
  await AudioService().init();

  runApp(const WordsArrowApp());
}

class WordsArrowApp extends StatelessWidget {
  const WordsArrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Words Arrow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Panteon',
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFA96646),
      ),
      home: const GameScreen(),
    );
  }
}
