import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../models/car.dart';
import 'three_d.dart';

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

class _Building {
  final Mesh3D mesh;
  final Rect footprint;

  _Building(this.mesh, this.footprint);
}

class SmokeParticle {
  Vector3 position;
  double age = 0;
  double life;
  double size;

  SmokeParticle(this.position, this.size) : life = 1.1 + math.Random().nextDouble() * 0.5;
}

/// 3D drift game: chase-camera view of a small city. Hold a slide to build
/// a score multiplier before the timer runs out.
class DriftGame extends FlameGame {
  DriftGame({required this.car, this.onGameOver});

  final CarModel car;
  final void Function(int score)? onGameOver;

  static const double worldSize = 400;
  static const double carRadius = 2.4;
  static const double runSeconds = 60;

  static const double _camDist = 11.0;
  static const double _camHeight = 5.2;

  final List<_Building> _buildings = <_Building>[];
  final List<SmokeParticle> _smoke = <SmokeParticle>[];
  final math.Random _rng = math.Random();

  late final Mesh3D _carMesh;
  late final Mesh3D _groundMesh;

  final Camera3D _camera = Camera3D();

  final ValueNotifier<HudData> hud = ValueNotifier<HudData>(
    const HudData(
      score: 0,
      multiplier: 1,
      timeLeft: runSeconds,
      speed: 0,
      drifting: false,
    ),
  );

  // Car state (2D plane: x -> world X, y -> world Z).
  Vector2 pos = Vector2(worldSize / 2, worldSize / 2);
  Vector2 vel = Vector2.zero();
  double angle = 0; // radians, 0 = facing +X

  // Input.
  bool throttle = false;
  bool brake = false;
  double steerInput = 0; // -1..1
  bool useTilt = false;
  double tiltValue = 0; // -1..1
  double sensitivity = 1.0;

  // Control layout (set from player settings).
  double buttonSize = 1.0;
  bool leftHanded = false;

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

  double _smokeTimer = 0;

  @override
  Future<void> onLoad() async {
    maxSpeed = car.maxSpeed;
    enginePower = car.enginePower;
    gripLat = car.gripLat;
    steerRate = car.steerRate;

    _carMesh = carMesh(car);
    _buildCity();
    _groundMesh = _buildGround();

    _camera.position = Vector3(pos.x, _camHeight, pos.y - _camDist);
    _camera.target = Vector3(pos.x, 0.9, pos.y);
  }

  void _buildCity() {
    const double block = 100;
    const double margin = 25;
    const double bsize = 60;

    const wallColors = <Color>[
      Color(0xFF3A3F4B),
      Color(0xFF454B58),
      Color(0xFF2F3440),
      Color(0xFF4A5162),
    ];
    const roofColors = <Color>[
      Color(0xFF6B7285),
      Color(0xFF7A8296),
      Color(0xFF5C6377),
    ];

    for (var gx = 0; gx < 4; gx++) {
      for (var gy = 0; gy < 4; gy++) {
        // Leave the central 2x2 blocks empty as an open drift plaza.
        if (gx >= 1 && gx <= 2 && gy >= 1 && gy <= 2) continue;

        final x = margin + gx * block + bsize / 2;
        final z = margin + gy * block + bsize / 2;
        final h = 22.0 + ((gx * 7 + gy * 13) % 5) * 9.0;

        final wall = wallColors[(gx + gy * 4) % wallColors.length];
        final roof = roofColors[(gx * 2 + gy) % roofColors.length];

        _buildings.add(_Building(
          buildingMesh(x, z, bsize, bsize, h, wall, roof, const Color(0xFFFFE08A)),
          Rect.fromLTWH(x - bsize / 2, z - bsize / 2, bsize, bsize),
        ));
      }
    }
  }

  Mesh3D _buildGround() {
    const w = worldSize;
    const block = 100.0;
    const margin = 25.0;
    const bsize = 60.0;

    const ground = Color(0xFF1B1D23);
    const road = Color(0xFF3A3D45);
    const line = Color(0x88FFFFFF);

    final faces = <Face>[];

    // Ground.
    faces.add(Face([
      Vector3(0, 0, 0),
      Vector3(w, 0, 0),
      Vector3(w, 0, w),
      Vector3(0, 0, w),
    ], ground));

    for (var i = 0; i < 3; i++) {
      final c = margin + i * block + bsize + 20;
      // Vertical street.
      faces.add(Face([
        Vector3(c - 20, 0.02, 0),
        Vector3(c + 20, 0.02, 0),
        Vector3(c + 20, 0.02, w),
        Vector3(c - 20, 0.02, w),
      ], road));
      faces.add(Face([
        Vector3(c - 0.3, 0.04, 0),
        Vector3(c + 0.3, 0.04, 0),
        Vector3(c + 0.3, 0.04, w),
        Vector3(c - 0.3, 0.04, w),
      ], line));

      // Horizontal street.
      faces.add(Face([
        Vector3(0, 0.02, c - 20),
        Vector3(w, 0.02, c - 20),
        Vector3(w, 0.02, c + 20),
        Vector3(0, 0.02, c + 20),
      ], road));
      faces.add(Face([
        Vector3(0, 0.04, c - 0.3),
        Vector3(w, 0.04, c - 0.3),
        Vector3(w, 0.04, c + 0.3),
        Vector3(0, 0.04, c + 0.3),
      ], line));
    }

    return Mesh3D(faces);
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
    _updateSmoke(dt);
    _updateCamera(dt);

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

    var vForward = vel.dot(forward);
    var vLateral = vel.dot(right);

    if (throttle) vForward += enginePower * dt;
    if (brake) {
      if (vForward > 10) {
        vForward -= 900 * dt;
      } else {
        vForward -= enginePower * 0.5 * dt;
      }
    }

    vForward -= vForward * 0.7 * dt;
    vForward = clampD(vForward, -maxSpeed * 0.4, maxSpeed);
    vLateral *= math.exp(-gripLat * 3.0 * dt);

    final steer = useTilt ? tiltValue : steerInput;
    final speedFactor = clampD(vForward.abs() / maxSpeed, 0.0, 1.0);
    final direction = vForward >= 0 ? 1.0 : -1.0;
    angle += steer * steerRate * sensitivity * speedFactor * direction * dt;

    vel = forward * vForward + right * vLateral;
    pos += vel * dt;
    _collide();
  }

  void _collide() {
    pos.x = clampD(pos.x, carRadius, worldSize - carRadius);
    pos.y = clampD(pos.y, carRadius, worldSize - carRadius);

    for (final building in _buildings) {
      final b = building.footprint;
      final nearestX = clampD(pos.x, b.left, b.right);
      final nearestY = clampD(pos.y, b.top, b.bottom);
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

  /// Local car-space point -> world position (uses the same yaw as the mesh).
  Vector3 _localToWorld(double lx, double ly, double lz) {
    final yaw = math.pi / 2 - angle;
    final c = math.cos(yaw);
    final s = math.sin(yaw);
    final wx = lx * c + lz * s;
    final wz = -lx * s + lz * c;
    return Vector3(pos.x + wx, ly, pos.y + wz);
  }

  void _updateSmoke(double dt) {
    if (_isDrifting() && vel.length > 90) {
      _smokeTimer -= dt;
      if (_smokeTimer <= 0) {
        _smokeTimer = 0.035;
        final half = car.length / 2;
        final hw = car.width / 2;
        for (final sx in <double>[-1, 1]) {
          _smoke.add(SmokeParticle(
            _localToWorld(sx * hw * 0.95, 0.35, -half * 0.65),
            1.0 + _rng.nextDouble() * 0.4,
          ));
        }
      }
    }

    for (final p in _smoke) {
      p.age += dt;
      p.position.y += dt * 0.9;
      p.size += dt * 2.2;
    }
    _smoke.removeWhere((p) => p.age >= p.life);
    if (_smoke.length > 160) {
      _smoke.removeRange(0, _smoke.length - 160);
    }
  }

  void _updateCamera(double dt) {
    final fx = math.cos(angle);
    final fz = math.sin(angle);
    final desired = Vector3(pos.x - fx * _camDist, _camHeight, pos.y - fz * _camDist);
    final t = clampD(dt * 4.5, 0.0, 1.0);
    _camera.position = _camera.position + (desired - _camera.position) * t;
    _camera.target = Vector3(pos.x, 0.9, pos.y);
  }

  @override
  void render(Canvas canvas) {
    final s = Size(size.x, size.y);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, s.width, s.height),
      Paint()..color = const Color(0xFF0C0E14),
    );

    final aspect = s.height <= 0 ? 1.0 : s.width / s.height;
    _camera.update(aspect);

    renderFlat(canvas, s, _camera, <Mesh3D>[_groundMesh]);

    final meshes = <Mesh3D>[];
    for (final b in _buildings) {
      meshes.add(b.mesh);
    }
    meshes.add(_carMesh.placed(Vector3(pos.x, 0, pos.y), math.pi / 2 - angle));
    renderMeshes(canvas, s, _camera, meshes);

    _drawSmoke(canvas);
  }

  void _drawSmoke(Canvas canvas) {
    for (final p in _smoke) {
      final c = _camera.vp.transform(
        Vector4(p.position.x, p.position.y, p.position.z, 1.0),
      );
      if (c.w <= 0.05) continue;

      final sx = ((c.x / c.w) * 0.5 + 0.5) * size.x;
      final sy = (1.0 - ((c.y / c.w) * 0.5 + 0.5)) * size.y;
      final r = clampD((p.size * size.y * 0.5) / c.w, 0.0, 400.0);
      final a = clampD(1.0 - p.age / p.life, 0.0, 1.0);

      canvas.drawCircle(
        Offset(sx, sy),
        r,
        Paint()..color = Colors.white.withValues(alpha: a * 0.45),
      );
    }
  }
}
