import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'game_state.dart';
import 'screens/garage_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // DriftCity is a landscape game: lock the whole app to landscape so the
  // garage and the game both rotate as soon as the app opens.
  SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PlayerData>(
      create: (_) => PlayerData()..load(),
      child: MaterialApp(
        title: 'DriftCity',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFFE53935),
          brightness: Brightness.dark,
        ),
        home: const GarageScreen(),
      ),
    );
  }
}
