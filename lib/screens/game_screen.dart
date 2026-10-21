import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../game/drift_game.dart';
import '../game_state.dart';
import '../models/car.dart';
import 'results_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.car});

  final CarModel car;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final DriftGame _game;
  StreamSubscription<AccelerometerEvent>? _accel;
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    final player = context.read<PlayerData>();

    _game = DriftGame(car: widget.car, onGameOver: _onGameOver);
    _game.useTilt = player.useTilt;
    _game.sensitivity = player.steerSensitivity;
    _game.buttonSize = player.buttonSize;
    _game.leftHanded = player.leftHanded;

    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    if (player.useTilt) {
      _accel = accelerometerEventStream().listen((event) {
        // Phone held in landscape: side-to-side tilt steers the car.
        _game.tiltValue = clampD(-event.y / 5.0, -1.0, 1.0);
      });
    }
  }

  void _onGameOver(int score) {
    if (_reported) return;
    _reported = true;

    final coins = (score / 10).floor();
    context.read<PlayerData>().addCoins(coins);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultsScreen(score: score, coins: coins, car: widget.car),
      ),
    );
  }

  @override
  void dispose() {
    _accel?.cancel();
    _game.hud.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GameWidget<DriftGame>(
        game: _game,
        initialActiveOverlays: const ['hud', 'controls'],
        overlayBuilderMap: {
          'hud': (context, game) => _HudOverlay(game: game),
          'controls': (context, game) => _ControlsOverlay(game: game),
          'pause': (context, game) => _PauseOverlay(
                onResume: () {
                  game.overlays.remove('pause');
                  game.resumeEngine();
                },
                onQuit: () => Navigator.of(context).pop(),
              ),
        },
      ),
    );
  }
}

class _HudOverlay extends StatelessWidget {
  const _HudOverlay({required this.game});

  final DriftGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HudData>(
      valueListenable: game.hud,
      builder: (context, data, _) {
        return Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statBlock('SCORE', '${data.score.round()}'),
                    _statBlock('TIME', '${data.timeLeft.ceil()}s'),
                    _statBlock('x${data.multiplier}', '${data.speed.round()} km/h'),
                    IconButton(
                      onPressed: () {
                        game.pauseEngine();
                        game.overlays.add('pause');
                      },
                      icon: const Icon(Icons.pause, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            if (data.drifting)
              const Positioned(
                left: 0,
                right: 0,
                bottom: 96,
                child: Center(
                  child: Text(
                    'DRIFT!',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _statBlock(String top, String bottom) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          top,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            letterSpacing: 2,
          ),
        ),
        Text(
          bottom,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({required this.game});

  final DriftGame game;

  @override
  Widget build(BuildContext context) {
    final size = game.buttonSize;

    final steering = Row(
      children: [
        if (!game.useTilt) ...[
          _HoldButton(
            icon: Icons.chevron_left,
            size: size,
            onDown: () => game.steerInput = -1,
            onUp: () => game.steerInput = 0,
          ),
          const SizedBox(width: 12),
          _HoldButton(
            icon: Icons.chevron_right,
            size: size,
            onDown: () => game.steerInput = 1,
            onUp: () => game.steerInput = 0,
          ),
        ] else
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text(
              'TILT STEERING ON',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
      ],
    );

    final pedals = Row(
      children: [
        _HoldButton(
          label: 'BRAKE',
          size: size,
          onDown: () => game.brake = true,
          onUp: () => game.brake = false,
        ),
        const SizedBox(width: 12),
        _HoldButton(
          label: 'GAS',
          size: size,
          onDown: () => game.throttle = true,
          onUp: () => game.throttle = false,
        ),
      ],
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: game.leftHanded
              ? [pedals, steering]
              : [steering, pedals],
        ),
      ),
    );
  }
}

class _HoldButton extends StatelessWidget {
  const _HoldButton({
    this.icon,
    this.label,
    required this.size,
    required this.onDown,
    required this.onUp,
  });

  final IconData? icon;
  final String? label;
  final double size;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    final d = 72.0 * size;
    return GestureDetector(
      onTapDown: (_) => onDown(),
      onTapUp: (_) => onUp(),
      onTapCancel: onUp,
      child: Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          color: Colors.white24,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white54),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: Colors.white, size: d * 0.5)
              : Text(
                  label ?? '',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14 * size,
                  ),
                ),
        ),
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.onResume, required this.onQuit});

  final VoidCallback onResume;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PAUSED',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: FilledButton(
                onPressed: onResume,
                child: const Text('RESUME'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 200,
              child: OutlinedButton(
                onPressed: onQuit,
                child: const Text('QUIT'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
