import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game_state.dart';
import '../models/car.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerData>();
    final car = player.selectedCar;
    final current = player.colorFor(car);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionHeader('Paint - ${car.name}'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: kCarPalette.map((color) {
                final selected = color.toARGB32() == current.toARGB32();
                return GestureDetector(
                  onTap: () => context.read<PlayerData>().setCarColor(car, color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.white24,
                        width: selected ? 3 : 1,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check, size: 20, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          const _SectionHeader('Controls'),
          SwitchListTile(
            title: const Text('Tilt steering'),
            subtitle: const Text('Steer by tilting the phone while driving'),
            value: player.useTilt,
            onChanged: (value) => context.read<PlayerData>().setTilt(value),
          ),
          SwitchListTile(
            title: const Text('Left-handed layout'),
            subtitle: const Text('Swap the steering and pedals to the other side'),
            value: player.leftHanded,
            onChanged: (value) =>
                context.read<PlayerData>().setLeftHanded(value),
          ),
          _SliderTile(
            title: 'Steering sensitivity',
            value: player.steerSensitivity,
            min: 0.5,
            max: 2.0,
            label: '${player.steerSensitivity.toStringAsFixed(2)}x',
            onChanged: (value) =>
                context.read<PlayerData>().setSensitivity(value),
          ),
          _SliderTile(
            title: 'Button size',
            value: player.buttonSize,
            min: 0.8,
            max: 1.5,
            label: '${(player.buttonSize * 100).round()}%',
            onChanged: (value) =>
                context.read<PlayerData>().setButtonSize(value),
          ),
          const Divider(),
          const _SectionHeader('Audio'),
          SwitchListTile(
            title: const Text('Sound'),
            subtitle: const Text('Audio is not wired up yet'),
            value: player.soundOn,
            onChanged: (value) => context.read<PlayerData>().setSound(value),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 2,
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.onChanged,
  });

  final String title;
  final double value;
  final double min;
  final double max;
  final String label;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title),
              Text(label, style: const TextStyle(color: Colors.white70)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
