import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../models/car.dart';

/// A flat polygon in 3D space, filled with a single colour.
class Face {
  final List<Vector3> points;
  final Color color;

  const Face(this.points, this.color);
}

/// A collection of faces that can be moved (translated + yawed) in the world.
class Mesh3D {
  final List<Face> faces;

  const Mesh3D(this.faces);

  /// Returns a copy of this mesh rotated around the Y axis and translated.
  Mesh3D placed(Vector3 offset, double yaw) {
    final rotation = Matrix4.rotationY(yaw);
    final result = <Face>[];
    for (final face in faces) {
      final points = <Vector3>[];
      for (final point in face.points) {
        final v = rotation.transform3(point);
        points.add(Vector3(v.x + offset.x, v.y + offset.y, v.z + offset.z));
      }
      result.add(Face(points, face.color));
    }
    return Mesh3D(result);
  }
}

/// Axis-aligned box between [min] and [max].
Mesh3D box(Vector3 min, Vector3 max, Color color) {
  final x0 = min.x, y0 = min.y, z0 = min.z;
  final x1 = max.x, y1 = max.y, z1 = max.z;

  final v = <Vector3>[
    Vector3(x0, y0, z0),
    Vector3(x1, y0, z0),
    Vector3(x1, y1, z0),
    Vector3(x0, y1, z0),
    Vector3(x0, y0, z1),
    Vector3(x1, y0, z1),
    Vector3(x1, y1, z1),
    Vector3(x0, y1, z1),
  ];

  return Mesh3D(<Face>[
    Face([v[4], v[5], v[6], v[7]], color), // +z
    Face([v[1], v[0], v[3], v[2]], color), // -z
    Face([v[0], v[4], v[7], v[3]], color), // -x
    Face([v[5], v[1], v[2], v[6]], color), // +x
    Face([v[3], v[7], v[6], v[2]], color), // top
    Face([v[0], v[1], v[5], v[4]], color), // bottom
  ]);
}

/// A stylised 3D car built from boxes: body, cabin, roof, wheels, lights.
/// Forward points towards +Z.
Mesh3D carMesh(CarModel car) {
  final l = car.length;
  final w = car.width;
  final h = car.height;
  final half = l / 2;
  final hw = w / 2;

  final body = car.color;
  final glass = const Color(0xFF1B1F27);
  final tyre = const Color(0xFF121216);
  final light = const Color(0xFFFFF3C4);
  final tail = const Color(0xFFE23B2E);

  final faces = <Face>[];

  // Lower body.
  faces.addAll(
    box(Vector3(-hw, 0.35, -half), Vector3(hw, 0.35 + h * 0.55, half), body).faces,
  );

  // Cabin (glass).
  faces.addAll(
    box(
      Vector3(-hw * 0.86, 0.35 + h * 0.55, -half * 0.15),
      Vector3(hw * 0.86, 0.35 + h * 0.95, half * 0.42),
      glass,
    ).faces,
  );

  // Roof.
  faces.addAll(
    box(
      Vector3(-hw * 0.8, 0.35 + h * 0.95, -half * 0.12),
      Vector3(hw * 0.8, 0.35 + h, half * 0.4),
      body,
    ).faces,
  );

  // Wheels.
  final wz = half * 0.62;
  for (final sx in <double>[-1, 1]) {
    for (final sz in <double>[-1, 1]) {
      final cx = sx * (hw + 0.03);
      final cz = sz * wz;
      faces.addAll(
        box(
          Vector3(cx - 0.14, 0.0, cz - 0.35),
          Vector3(cx + 0.14, 0.62, cz + 0.35),
          tyre,
        ).faces,
      );
    }
  }

  // Head lights.
  faces.addAll(
    box(Vector3(-hw * 0.8, 0.6, half - 0.06), Vector3(-hw * 0.28, 0.82, half + 0.02), light).faces,
  );
  faces.addAll(
    box(Vector3(hw * 0.28, 0.6, half - 0.06), Vector3(hw * 0.8, 0.82, half + 0.02), light).faces,
  );

  // Tail lights.
  faces.addAll(
    box(Vector3(-hw * 0.85, 0.6, -half - 0.02), Vector3(-hw * 0.35, 0.8, -half + 0.06), tail).faces,
  );
  faces.addAll(
    box(Vector3(hw * 0.35, 0.6, -half - 0.02), Vector3(hw * 0.85, 0.8, -half + 0.06), tail).faces,
  );

  return Mesh3D(faces);
}

/// A city block: walls, a roof slab and window bands on each side.
Mesh3D buildingMesh(
  double x,
  double z,
  double w,
  double d,
  double h,
  Color wall,
  Color roof,
  Color window,
) {
  final faces = <Face>[];

  faces.addAll(
    box(Vector3(x - w / 2, 0, z - d / 2), Vector3(x + w / 2, h, z + d / 2), wall).faces,
  );

  // Roof slab.
  faces.add(
    Face([
      Vector3(x - w / 2 - 0.15, h + 0.05, z - d / 2 - 0.15),
      Vector3(x + w / 2 + 0.15, h + 0.05, z - d / 2 - 0.15),
      Vector3(x + w / 2 + 0.15, h + 0.05, z + d / 2 + 0.15),
      Vector3(x - w / 2 - 0.15, h + 0.05, z + d / 2 + 0.15),
    ], roof),
  );

  // Window bands (one per wall), nudged outwards to sit on the surface.
  final y0 = h * 0.45;
  final y1 = h * 0.8;
  const o = 0.03;
  final insetX = w * 0.15;
  final insetZ = d * 0.15;

  faces.add(Face([
    Vector3(x - w / 2 + insetX, y0, z - d / 2 - o),
    Vector3(x + w / 2 - insetX, y0, z - d / 2 - o),
    Vector3(x + w / 2 - insetX, y1, z - d / 2 - o),
    Vector3(x - w / 2 + insetX, y1, z - d / 2 - o),
  ], window));

  faces.add(Face([
    Vector3(x - w / 2 + insetX, y0, z + d / 2 + o),
    Vector3(x + w / 2 - insetX, y0, z + d / 2 + o),
    Vector3(x + w / 2 - insetX, y1, z + d / 2 + o),
    Vector3(x - w / 2 + insetX, y1, z + d / 2 + o),
  ], window));

  faces.add(Face([
    Vector3(x - w / 2 - o, y0, z - d / 2 + insetZ),
    Vector3(x - w / 2 - o, y0, z + d / 2 - insetZ),
    Vector3(x - w / 2 - o, y1, z + d / 2 - insetZ),
    Vector3(x - w / 2 - o, y1, z - d / 2 + insetZ),
  ], window));

  faces.add(Face([
    Vector3(x + w / 2 + o, y0, z - d / 2 + insetZ),
    Vector3(x + w / 2 + o, y0, z + d / 2 - insetZ),
    Vector3(x + w / 2 + o, y1, z + d / 2 - insetZ),
    Vector3(x + w / 2 + o, y1, z - d / 2 + insetZ),
  ], window));

  return Mesh3D(faces);
}

/// Right-handed look-at view matrix (camera looks down its own -Z).
Matrix4 _lookAt(Vector3 eye, Vector3 center, Vector3 up) {
  final forward = center - eye;
  forward.normalize();
  final right = forward.cross(up);
  right.normalize();
  final trueUp = right.cross(forward);

  final m = Matrix4.identity();
  m.setRow(0, Vector4(right.x, right.y, right.z, -right.dot(eye)));
  m.setRow(1, Vector4(trueUp.x, trueUp.y, trueUp.z, -trueUp.dot(eye)));
  m.setRow(2, Vector4(-forward.x, -forward.y, -forward.z, forward.dot(eye)));
  m.setRow(3, Vector4(0.0, 0.0, 0.0, 1.0));
  return m;
}

/// Standard right-handed perspective projection.
Matrix4 _perspective(double fovY, double aspect, double near, double far) {
  final f = 1.0 / math.tan(fovY / 2.0);
  final nf = 1.0 / (near - far);
  final m = Matrix4.identity();
  m.setRow(0, Vector4(f / aspect, 0.0, 0.0, 0.0));
  m.setRow(1, Vector4(0.0, f, 0.0, 0.0));
  m.setRow(2, Vector4(0.0, 0.0, (far + near) * nf, 2.0 * far * near * nf));
  m.setRow(3, Vector4(0.0, 0.0, -1.0, 0.0));
  return m;
}

/// Perspective camera.
class Camera3D {
  Vector3 position = Vector3(0, 6, -12);
  Vector3 target = Vector3(0, 1, 0);
  final Vector3 up = Vector3(0, 1, 0);
  double fov = 60 * math.pi / 180;
  double near = 0.05;
  double far = 2000;
  late Matrix4 vp;

  void update(double aspect) {
    final view = _lookAt(position, target, up);
    final proj = _perspective(fov, aspect, near, far);
    vp = proj * view;
  }
}

class _Projected {
  final List<Offset> pts;
  final Color color;
  final double depth;

  _Projected(this.pts, this.color, this.depth);
}

const double _nearEps = 0.05;

/// Sutherland-Hodgman clip of a polygon against w > eps, in clip space.
List<Vector4> _clipNear(List<Vector4> poly) {
  final out = <Vector4>[];
  final n = poly.length;
  for (var i = 0; i < n; i++) {
    final cur = poly[i];
    final nxt = poly[(i + 1) % n];
    final curIn = cur.w > _nearEps;
    final nxtIn = nxt.w > _nearEps;
    if (curIn) out.add(cur);
    if (curIn != nxtIn) {
      final t = (_nearEps - cur.w) / (nxt.w - cur.w);
      out.add(Vector4(
        cur.x + (nxt.x - cur.x) * t,
        cur.y + (nxt.y - cur.y) * t,
        cur.z + (nxt.z - cur.z) * t,
        _nearEps,
      ));
    }
  }
  return out;
}

List<_Projected> _project(List<Mesh3D> meshes, Camera3D cam, Size size) {
  final items = <_Projected>[];
  for (final mesh in meshes) {
    for (final face in mesh.faces) {
      final clip = <Vector4>[];
      for (final p in face.points) {
        clip.add(cam.vp.transform(Vector4(p.x, p.y, p.z, 1.0)));
      }
      final clipped = _clipNear(clip);
      if (clipped.length < 3) continue;

      final pts = <Offset>[];
      var depth = 0.0;
      for (final c in clipped) {
        final sx = ((c.x / c.w) * 0.5 + 0.5) * size.width;
        final sy = (1.0 - ((c.y / c.w) * 0.5 + 0.5)) * size.height;
        pts.add(Offset(sx, sy));
        depth += c.w;
      }
      items.add(_Projected(pts, _shade(face), depth / clipped.length));
    }
  }
  return items;
}

Color _shade(Face face) {
  if (face.points.length < 3) return face.color;
  final a = face.points[0];
  final b = face.points[1];
  final c = face.points[2];
  final n = (b - a).cross(c - a);
  if (n.length2 < 1e-9) return face.color;
  n.normalize();
  final light = Vector3(0.4, 0.95, 0.3)..normalize();
  final k = 0.5 + 0.5 * n.dot(light).abs();
  return Color.lerp(Colors.black, face.color, k)!;
}

void _paint(Canvas canvas, _Projected item) {
  final pts = item.pts;
  final path = Path()..moveTo(pts[0].dx, pts[0].dy);
  for (var i = 1; i < pts.length; i++) {
    path.lineTo(pts[i].dx, pts[i].dy);
  }
  path.close();
  canvas.drawPath(path, Paint()..color = item.color);
}

/// Draws meshes with painter's-algorithm depth sorting (far faces first).
void renderMeshes(Canvas canvas, Size size, Camera3D cam, List<Mesh3D> meshes) {
  final items = _project(meshes, cam, size);
  items.sort((a, b) => b.depth.compareTo(a.depth));
  for (final item in items) {
    _paint(canvas, item);
  }
}

/// Draws meshes in the given order, without sorting (for ground/roads).
void renderFlat(Canvas canvas, Size size, Camera3D cam, List<Mesh3D> meshes) {
  for (final item in _project(meshes, cam, size)) {
    _paint(canvas, item);
  }
}
