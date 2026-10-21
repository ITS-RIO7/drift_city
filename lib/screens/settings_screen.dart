import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerData>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Sound'),
            subtitle: const Text('Audio is not wired up yet'),
            value: player.soundOn,
            onChanged: (value) => context.read<PlayerData>().setSound(value),
          ),
          SwitchListTile(
            title: const Text('Tilt steering'),
            subtitle: const Text('Steer by tilting the phone while driving'),
            value: player.useTilt,
            onChanged: (value) => context.read<PlayerData>().setTilt(value),
          ),
        ],
      ),
    );
  }
}
