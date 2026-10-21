import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'game_state.dart';
import 'screens/garage_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
