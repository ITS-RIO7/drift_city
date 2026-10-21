import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../game/three_d.dart';
import '../models/car.dart';

/// A slowly rotating 360-degree 3D view of a car, used in the garage.
class CarViewer extends StatefulWidget {
  const CarViewer({super.key, required this.car});

  final CarModel car;

  @override
  State<CarViewer> createState() => _CarViewerState();
}

class _CarViewerState extends State<CarViewer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late Mesh3D _mesh;
  double _t = 0;

  @override
  void initState() {
    super.initState();
    _mesh = carMesh(widget.car);
    _ticker = createTicker((elapsed) {
      setState(() => _t = elapsed.inMilliseconds / 1000.0);
    })
      ..start();
  }

  @override
  void didUpdateWidget(covariant CarViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.car.id != widget.car.id) {
      _mesh = carMesh(widget.car);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CarPainter(mesh: _mesh, t: _t),
      size: Size.infinite,
    );
  }
}

class _CarPainter extends CustomPainter {
  _CarPainter({required this.mesh, required this.t});

  final Mesh3D mesh;
  final double t;
  final Camera3D _camera = Camera3D();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF232734), Color(0xFF0B0D12)],
          radius: 0.8,
        ).createShader(rect),
    );

    final angle = t * 0.55;
    const radius = 9.5;
    _camera.position =
        Vector3(math.sin(angle) * radius, 3.0, math.cos(angle) * radius);
    _camera.target = Vector3(0, 0.85, 0);
    _camera.fov = 45 * math.pi / 180;
    _camera.update(size.height <= 0 ? 1.0 : size.width / size.height);

    final floor = Mesh3D(<Face>[
      Face([
        Vector3(-9, 0, -9),
        Vector3(9, 0, -9),
        Vector3(9, 0, 9),
        Vector3(-9, 0, 9),
      ], const Color(0xFF171A21)),
    ]);

    renderFlat(canvas, size, _camera, <Mesh3D>[floor]);
    renderMeshes(canvas, size, _camera, <Mesh3D>[mesh]);
  }

  @override
  bool shouldRepaint(covariant _CarPainter oldDelegate) => true;
}
