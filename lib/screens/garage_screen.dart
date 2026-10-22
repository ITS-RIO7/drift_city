import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_info.dart';
import '../game_state.dart';
import '../models/car.dart';
import '../widgets/car_viewer.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

/// The landing screen: a 360-degree 3D car with arrows to change car,
/// a green PLAY button and settings at the top.
class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  int _index = 0;
  bool _initialised = false;

  void _move(int delta, PlayerData player) {
    setState(() {
      _index = (_index + delta + kCars.length) % kCars.length;
    });
    final car = kCars[_index];
    if (player.isUnlocked(car.id)) {
      player.selectCar(car.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerData>();

    if (!_initialised) {
      final found = kCars.indexWhere((c) => c.id == player.selectedCarId);
      _index = found < 0 ? 0 : found;
      _initialised = true;
    }

    final car = kCars[_index];
    final unlocked = player.isUnlocked(car.id);
    final bodyColor = player.colorFor(car);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D12),
      body: Stack(
        children: [
          Positioned.fill(child: CarViewer(car: car, bodyColor: bodyColor)),

          // Top bar: coins + settings.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _Coins(coins: player.coins),
                      const SizedBox(width: 10),
                      Text(
                        'v$kAppVersion',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    icon: const Icon(Icons.settings, color: Colors.white, size: 30),
                  ),
                ],
              ),
            ),
          ),

          // Arrows to change car.
          Align(
            alignment: Alignment.centerLeft,
            child: _ArrowButton(
              icon: Icons.chevron_left,
              onTap: () => _move(-1, player),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _ArrowButton(
              icon: Icons.chevron_right,
              onTap: () => _move(1, player),
            ),
          ),

          // Car name, stats and action.
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      car.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StatRow(car: car),
                    const SizedBox(height: 12),
                    _action(context, player, car, unlocked, bodyColor),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(
    BuildContext context,
    PlayerData player,
    CarModel car,
    bool unlocked,
    Color bodyColor,
  ) {
    if (unlocked) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2ECC40),
          foregroundColor: Colors.black,
          minimumSize: const Size(210, 54),
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        // Navigate immediately: selecting the car only updates local state
        // and persists in the background, so nothing can block the tap.
        onPressed: () {
          player.selectCar(car.id);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GameScreen(car: car, bodyColor: bodyColor),
            ),
          );
        },
        icon: const Icon(Icons.play_arrow, size: 28),
        label: const Text('PLAY'),
      );
    }

    final canAfford = player.coins >= car.price;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, size: 16, color: Colors.white70),
            const SizedBox(width: 6),
            Text(
              '${car.price} coins',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: canAfford ? const Color(0xFFF2C400) : Colors.white24,
            foregroundColor: Colors.black,
            minimumSize: const Size(210, 54),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          onPressed: () async {
            final ok = await player.unlockCar(car);
            if (!ok && context.mounted) {
              final missing = car.price - player.coins;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Need $missing more coins')),
              );
            }
          },
          icon: const Icon(Icons.lock_open, size: 22),
          label: Text(canAfford ? 'UNLOCK' : 'LOCKED'),
        ),
      ],
    );
  }
}

class _Coins extends StatelessWidget {
  const _Coins({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
          const SizedBox(width: 6),
          Text('$coins', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white12,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white30),
          ),
          child: Icon(icon, color: Colors.white, size: 34),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.car});

  final CarModel car;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stat('SPD', car.speed),
        const SizedBox(width: 14),
        _stat('GRIP', car.grip),
        const SizedBox(width: 14),
        _stat('DRIFT', car.drift),
      ],
    );
  }

  Widget _stat(String label, double value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white54, letterSpacing: 1),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 62,
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: Colors.white12,
            ),
          ),
        ),
      ],
    );
  }
}
