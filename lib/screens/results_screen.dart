import 'package:flutter/material.dart';

import '../models/car.dart';
import 'game_screen.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({
    super.key,
    required this.score,
    required this.coins,
    required this.car,
    this.bodyColor,
  });

  final int score;
  final int coins;
  final CarModel car;
  final Color? bodyColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'RUN COMPLETE',
              style: TextStyle(letterSpacing: 4),
            ),
            const SizedBox(height: 8),
            Text(
              '$score',
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                const SizedBox(width: 6),
                Text('+$coins coins'),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 220,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) =>
                          GameScreen(car: car, bodyColor: bodyColor),
                    ),
                  );
                },
                child: const Text('DRIFT AGAIN'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 220,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('HOME'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
