import 'dart:math' as math;

import 'package:flame/components.dart' show Vector2;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../models/car.dart';

/// Small clamp helper (avoids num/double casts from [num.clamp]).
double clampD(double value, double low, double high) {
  if (value < low) return low;
  if (value > high) return high;
  return value;
}

/// Snapshot of the numbers the HUD shows, refreshed every frame.
class HudData {
  final double score;
  final int multiplier;
  final double timeLeft;
  final double speed;
  final bool drifting;

  const HudData({
    required this.score,
    required this.multiplier,
    required this.timeLeft,
    required this.speed,
    required this.drifting,
  });
}

/// Top-down tilted (2.5D) drift game: drive around a small city, hold a
/// slide to build a score multiplier before the timer runs out.
class DriftGame extends FlameGame {
  DriftGame({required this.car, this.onGameOver});

  final CarModel car;
  final void Function(int score)? onGameOver;

  static const double worldSize = 2400;
  static const double carRadius = 16;
  static const double runSeconds = 60;

  final List<Rect> buildings = <Rect>[];

  final ValueNotifier<HudData> hud = ValueNotifier<HudData>(
    const HudData(
      score: 0,
      multiplier: 1,
      timeLeft: runSeconds,
      speed: 0,
      drifting: false,
    ),
  );

  // Car state.
  Vector2 pos = Vector2(worldSize / 2, worldSize / 2);
  Vector2 vel = Vector2.zero();
  double angle = 0; // radians, 0 = facing right

  // Input.
  bool throttle = false;
  bool brake = false;
  double steerInput = 0; // -1..1
  bool useTilt = false;
  double tiltValue = 0; // -1..1

  // Scoring.
  double score = 0;
  double combo = 0;
  int multiplier = 1;
  double timeLeft = runSeconds;
  bool isOver = false;

  late double maxSpeed;
  late double enginePower;
  late double gripLat;
  late double steerRate;

  @override
  Future<void> onLoad() async {
    maxSpeed = car.maxSpeed;
    enginePower = car.enginePower;
    gripLat = car.gripLat;
    steerRate = car.steerRate;
    _buildCity();
  }

  void _buildCity() {
    const double block = 600;
    const double margin = 150;
    const double bsize = 380;
    for (int gx = 0; gx < 4; gx++) {
      for (int gy = 0; gy < 4; gy++) {
        // Leave the central 2x2 blocks empty as an open drift plaza.
        if (gx >= 1 && gx <= 2 && gy >= 1 && gy <= 2) continue;
        buildings.add(
          Rect.fromLTWH(margin + gx * block, margin + gy * block, bsize, bsize),
        );
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isOver) return;

    timeLeft -= dt;
    if (timeLeft <= 0) {
      timeLeft = 0;
      isOver = true;
      hud.value = HudData(
        score: score,
        multiplier: multiplier,
        timeLeft: 0,
        speed: vel.length,
        drifting: false,
      );
      onGameOver?.call(score.round());
      return;
    }

    _physics(dt);
    _score(dt);

    hud.value = HudData(
      score: score,
      multiplier: multiplier,
      timeLeft: timeLeft,
      speed: vel.length,
      drifting: _isDrifting(),
    );
  }

  bool _isDrifting() {
    final lateral = vel.dot(Vector2(-math.sin(angle), math.cos(angle))).abs();
    return vel.length > 80 && lateral > 40;
  }

  void _physics(double dt) {
    final forward = Vector2(math.cos(angle), math.sin(angle));
    final right = Vector2(-math.sin(angle), math.cos(angle));

    double vForward = vel.dot(forward);
    double vLateral = vel.dot(right);

    if (throttle) vForward += enginePower * dt;
    if (brake) {
      if (vForward > 10) {
        vForward -= 900 * dt;
      } else {
        vForward -= enginePower * 0.5 * dt;
      }
    }

    // Rolling drag.
    vForward -= vForward * 0.7 * dt;
    vForward = clampD(vForward, -maxSpeed * 0.4, maxSpeed);

    // Lateral grip: the lower gripLat, the longer the slide lasts.
    vLateral *= math.exp(-gripLat * 3.0 * dt);

    // Steering only bites when the car is actually moving.
    final steer = useTilt ? tiltValue : steerInput;
    final speedFactor = clampD(vForward.abs() / maxSpeed, 0.0, 1.0);
    final direction = vForward >= 0 ? 1.0 : -1.0;
    angle += steer * steerRate * speedFactor * direction * dt;

    vel = forward * vForward + right * vLateral;
    pos += vel * dt;
    _collide();
  }

  void _collide() {
    pos.x = clampD(pos.x, carRadius, worldSize - carRadius);
    pos.y = clampD(pos.y, carRadius, worldSize - carRadius);

    for (final building in buildings) {
      final nearestX = clampD(pos.x, building.left, building.right);
      final nearestY = clampD(pos.y, building.top, building.bottom);
      final dx = pos.x - nearestX;
      final dy = pos.y - nearestY;
      final dist = math.sqrt(dx * dx + dy * dy);

      if (dist < carRadius) {
        final nx = dist == 0 ? 1.0 : dx / dist;
        final ny = dist == 0 ? 0.0 : dy / dist;
        final push = carRadius - dist;
        pos.x += nx * push;
        pos.y += ny * push;

        final impact = vel.length;
        final vn = vel.x * nx + vel.y * ny;
        vel.x -= 1.5 * vn * nx;
        vel.y -= 1.5 * vn * ny;
        vel *= 0.4;

        if (impact > 120) {
          combo = 0;
          multiplier = 1;
          score = math.max(0, score - 30);
        }
      }
    }
  }

  void _score(double dt) {
    if (_isDrifting()) {
      combo += dt;
      multiplier = 1 + (combo / 1.5).floor();
      if (multiplier > 20) multiplier = 20;
      final lateral = vel.dot(Vector2(-math.sin(angle), math.cos(angle))).abs();
      score += lateral * dt * 0.6 * multiplier;
    } else {
      combo = math.max(0, combo - dt * 1.5);
      if (combo == 0) multiplier = 1;
    }
  }

  @override
  void render(Canvas canvas) {
    final offset = Offset(size.x / 2 - pos.x, size.y / 2 - pos.y);
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    _drawWorld(canvas);
    for (final building in buildings) {
      _drawBuilding(canvas, building);
    }
    _drawCar(canvas);

    canvas.restore();
  }

  void _drawWorld(Canvas canvas) {
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, worldSize, worldSize),
      Paint()..color = const Color(0xFF23232A),
    );

    final road = Paint()..color = const Color(0xFF37373F);
    const double block = 600;
    const double margin = 150;
    const double bsize = 380;
    for (int i = 0; i < 4; i++) {
      final center = margin + i * block + bsize / 2;
      canvas.drawRect(
        Rect.fromLTWH(center - 110, 0, 220, worldSize),
        road,
      );
      canvas.drawRect(
        Rect.fromLTWH(0, center - 110, worldSize, 220),
        road,
      );
    }

    final dash = Paint()..color = const Color(0x66FFFFFF);
    for (int i = 0; i < 4; i++) {
      final center = margin + i * block + bsize / 2;
      for (double y = 0; y < worldSize; y += 60) {
        canvas.drawRect(Rect.fromLTWH(center - 3, y, 6, 30), dash);
      }
      for (double x = 0; x < worldSize; x += 60) {
        canvas.drawRect(Rect.fromLTWH(x, center - 3, 30, 6), dash);
      }
    }

    final wall = Paint()..color = const Color(0xFF4A4A55);
    const double t = 20;
    canvas.drawRect(const Rect.fromLTWH(0, 0, worldSize, t), wall);
    canvas.drawRect(const Rect.fromLTWH(0, worldSize - t, worldSize, t), wall);
    canvas.drawRect(const Rect.fromLTWH(0, 0, t, worldSize), wall);
    canvas.drawRect(const Rect.fromLTWH(worldSize - t, 0, t, worldSize), wall);
  }

  void _drawBuilding(Canvas canvas, Rect base) {
    const double height = 70;

    canvas.drawRect(
      Rect.fromLTWH(base.left + 8, base.top + 8, base.width, base.height),
      Paint()..color = const Color(0x55000000),
    );

    final roof = Rect.fromLTWH(base.left, base.top - height, base.width, base.height);
    final front = Rect.fromLTWH(base.left, base.bottom - height, base.width, height);

    canvas.drawRect(front, Paint()..color = const Color(0xFF3E3E48));
    canvas.drawRect(roof, Paint()..color = const Color(0xFF6B6B78));

    final window = Paint()..color = const Color(0xFFFFE08A);
    for (double x = front.left + 24; x < front.right - 24; x += 56) {
      for (double y = front.top + 14; y < front.bottom - 14; y += 30) {
        canvas.drawRect(Rect.fromLTWH(x, y, 20, 16), window);
      }
    }
  }

  void _drawCar(Canvas canvas) {
    canvas.save();
    canvas.translate(pos.x, pos.y);
    canvas.rotate(angle);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: const Offset(3, 3),
          width: 40,
          height: 24,
        ),
        const Radius.circular(7),
      ),
      Paint()..color = const Color(0x66000000),
    );

    final wheel = Paint()..color = const Color(0xFF15151A);
    for (final wx in <double>[10, -10]) {
      for (final wy in <double>[12, -12]) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset(wx, wy), width: 12, height: 7),
          wheel,
        );
      }
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 40, height: 24),
        const Radius.circular(7),
      ),
      Paint()..color = car.color,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(5, 0), width: 12, height: 18),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF1B1F27),
    );

    canvas.drawRect(
      Rect.fromCenter(center: const Offset(19, 0), width: 3, height: 14),
      Paint()..color = Colors.white70,
    );

    canvas.restore();
  }
}
