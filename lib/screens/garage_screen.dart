import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game_state.dart';
import '../models/car.dart';

class GarageScreen extends StatelessWidget {
  const GarageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerData>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Garage'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                const SizedBox(width: 6),
                Text('${player.coins}'),
              ],
            ),
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(12),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
        children: kCars
            .map((car) => _CarTile(car: car, player: player))
            .toList(),
      ),
    );
  }
}

class _CarTile extends StatelessWidget {
  const _CarTile({required this.car, required this.player});

  final CarModel car;
  final PlayerData player;

  @override
  Widget build(BuildContext context) {
    final unlocked = player.isUnlocked(car.id);
    final selected = player.selectedCarId == car.id;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 22,
                  decoration: BoxDecoration(
                    color: car.color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    car.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _StatBar(label: 'SPD', value: car.speed),
            _StatBar(label: 'GRIP', value: car.grip),
            _StatBar(label: 'DRIFT', value: car.drift),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: _actionButton(context, unlocked, selected),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context, bool unlocked, bool selected) {
    if (selected) {
      return const FilledButton(onPressed: null, child: Text('SELECTED'));
    }
    if (unlocked) {
      return FilledButton(
        onPressed: () => context.read<PlayerData>().selectCar(car.id),
        child: const Text('SELECT'),
      );
    }

    final canAfford = player.coins >= car.price;
    return FilledButton.tonal(
      onPressed: () async {
        final ok = await context.read<PlayerData>().unlockCar(car);
        if (!ok && context.mounted) {
          final missing = car.price - player.coins;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Need $missing more coins')),
          );
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(canAfford ? Icons.lock_open : Icons.lock, size: 14),
          const SizedBox(width: 6),
          Text(canAfford ? 'UNLOCK ${car.price}' : '${car.price}'),
        ],
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  const _StatBar({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(label, style: const TextStyle(fontSize: 11)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
