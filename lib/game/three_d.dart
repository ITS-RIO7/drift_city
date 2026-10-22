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

/// Axis-aligned box between [min] and [max]. Faces wind outwards.
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
    Face([v[3], v[7], v[6], v[2]], color), // +y (top)
    Face([v[0], v[1], v[5], v[4]], color), // -y
  ]);
}

/// A stylised but detailed 3D car.
///
/// The lower body is a tapered hull (so it has shoulders instead of looking
/// like a flat slab), with a slanted greenhouse, a grille, head/tail lights,
/// mirrors, a ducktail and four wheels. Every face winds outwards so the
/// renderer can cull back faces. Forward points towards +Z.
/// [body] overrides the car's paint colour.
Mesh3D carMesh(CarModel car, {Color? body}) {
  final l = car.length;
  final w = car.width;
  final h = car.height;
  final half = l / 2;
  final hw = w / 2;

  final paint = body ?? car.color;
  final glass = const Color(0xFF222A36);
  final tyre = const Color(0xFF101014);
  final rim = const Color(0xFFC6CBD2);
  final lightF = const Color(0xFFFFF6D0);
  final lightR = const Color(0xFFE23B2E);
  final grille = const Color(0xFF16181E);

  final y0 = 0.22; // sill
  final yBelt = y0 + h * 0.58; // beltline
  final yRoof = y0 + h * 0.98; // roof
  final hwS = hw * 0.98; // half-width at the sill
  final hwB = hw * 0.86; // half-width at the beltline
  final hS = half;
  final hB = half * 0.97;

  final faces = <Face>[];

  // ---- lower body: tapered hull ----
  // bottom (-Y)
  faces.add(Face([
    Vector3(-hwS, y0, -hS),
    Vector3(hwS, y0, -hS),
    Vector3(hwS, y0, hS),
    Vector3(-hwS, y0, hS),
  ], paint));
  // deck / top (+Y)
  faces.add(Face([
    Vector3(-hwB, yBelt, hB),
    Vector3(hwB, yBelt, hB),
    Vector3(hwB, yBelt, -hB),
    Vector3(-hwB, yBelt, -hB),
  ], paint));
  // left (-X)
  faces.add(Face([
    Vector3(-hwS, y0, -hS),
    Vector3(-hwS, y0, hS),
    Vector3(-hwB, yBelt, hB),
    Vector3(-hwB, yBelt, -hB),
  ], paint));
  // right (+X)
  faces.add(Face([
    Vector3(hwS, y0, hS),
    Vector3(hwS, y0, -hS),
    Vector3(hwB, yBelt, -hB),
    Vector3(hwB, yBelt, hB),
  ], paint));
  // front (+Z)
  faces.add(Face([
    Vector3(-hwS, y0, hS),
    Vector3(hwS, y0, hS),
    Vector3(hwB, yBelt, hB),
    Vector3(-hwB, yBelt, hB),
  ], paint));
  // rear (-Z)
  faces.add(Face([
    Vector3(hwS, y0, -hS),
    Vector3(-hwS, y0, -hS),
    Vector3(-hwB, yBelt, -hB),
    Vector3(hwB, yBelt, -hB),
  ], paint));

  // ---- greenhouse ----
  final cabFront = half * 0.30;
  final cabBack = -half * 0.42;
  final cabHw = hwB * 0.98;
  final roofHw = hwB * 0.78;
  final roofFront = half * 0.10;
  final roofBack = -half * 0.32;
  final yCab = yBelt + h * 0.02;

  // windshield
  faces.add(Face([
    Vector3(-cabHw, yCab, cabFront),
    Vector3(cabHw, yCab, cabFront),
    Vector3(roofHw, yRoof, roofFront),
    Vector3(-roofHw, yRoof, roofFront),
  ], glass));
  // rear window
  faces.add(Face([
    Vector3(cabHw, yCab, cabBack),
    Vector3(-cabHw, yCab, cabBack),
    Vector3(-roofHw, yRoof, roofBack),
    Vector3(roofHw, yRoof, roofBack),
  ], glass));
  // left glass
  faces.add(Face([
    Vector3(-cabHw, yCab, cabBack),
    Vector3(-cabHw, yCab, cabFront),
    Vector3(-roofHw, yRoof, roofFront),
    Vector3(-roofHw, yRoof, roofBack),
  ], glass));
  // right glass
  faces.add(Face([
    Vector3(cabHw, yCab, cabFront),
    Vector3(cabHw, yCab, cabBack),
    Vector3(roofHw, yRoof, roofBack),
    Vector3(roofHw, yRoof, roofFront),
  ], glass));
  // roof
  faces.add(Face([
    Vector3(-roofHw, yRoof, roofFront),
    Vector3(roofHw, yRoof, roofFront),
    Vector3(roofHw, yRoof, roofBack),
    Vector3(-roofHw, yRoof, roofBack),
  ], paint));

  // ---- front details ----
  final zF = hS + 0.03;
  faces.add(Face([
    Vector3(-hwS * 0.60, y0 + h * 0.06, zF),
    Vector3(hwS * 0.60, y0 + h * 0.06, zF),
    Vector3(hwS * 0.60, yBelt - h * 0.26, zF),
    Vector3(-hwS * 0.60, yBelt - h * 0.26, zF),
  ], grille));
  faces.add(Face([
    Vector3(-hwS * 0.92, yBelt - h * 0.30, zF),
    Vector3(-hwS * 0.38, yBelt - h * 0.30, zF),
    Vector3(-hwS * 0.38, yBelt - h * 0.14, zF),
    Vector3(-hwS * 0.92, yBelt - h * 0.14, zF),
  ], lightF));
  faces.add(Face([
    Vector3(hwS * 0.38, yBelt - h * 0.30, zF),
    Vector3(hwS * 0.92, yBelt - h * 0.30, zF),
    Vector3(hwS * 0.92, yBelt - h * 0.14, zF),
    Vector3(hwS * 0.38, yBelt - h * 0.14, zF),
  ], lightF));

  // ---- rear details ----
  final zR = -hS - 0.03;
  faces.add(Face([
    Vector3(-hwS * 0.36, yBelt - h * 0.30, zR),
    Vector3(-hwS * 0.90, yBelt - h * 0.30, zR),
    Vector3(-hwS * 0.90, yBelt - h * 0.12, zR),
    Vector3(-hwS * 0.36, yBelt - h * 0.12, zR),
  ], lightR));
  faces.add(Face([
    Vector3(hwS * 0.90, yBelt - h * 0.30, zR),
    Vector3(hwS * 0.36, yBelt - h * 0.30, zR),
    Vector3(hwS * 0.36, yBelt - h * 0.12, zR),
    Vector3(hwS * 0.90, yBelt - h * 0.12, zR),
  ], lightR));

  // mirrors
  for (final s in <double>[-1, 1]) {
    faces.addAll(box(
      Vector3(s * (hwB - 0.05), yCab, cabFront - 0.20),
      Vector3(s * (hwB + 0.12), yCab + 0.09, cabFront - 0.05),
      paint,
    ).faces);
  }

  // ducktail spoiler
  faces.addAll(box(
    Vector3(-hwB * 0.95, yBelt - h * 0.01, -hS - 0.10),
    Vector3(hwB * 0.95, yBelt + 0.06, -hS - 0.01),
    paint,
  ).faces);

  // ---- wheels + rims ----
  final wz = half * 0.58;
  const wr = 0.36;
  for (final sx in <double>[-1, 1]) {
    for (final sz in <double>[-1, 1]) {
      final cx = sx * (hwS - 0.06);
      final cz = sz * wz;
      faces.addAll(box(
        Vector3(cx - 0.15, 0.0, cz - wr),
        Vector3(cx + 0.15, wr * 2, cz + wr),
        tyre,
      ).faces);

      final outer = cx + sx * 0.155;
      if (sx > 0) {
        faces.add(Face([
          Vector3(outer, wr * 0.55, cz - wr * 0.55),
          Vector3(outer, wr * 0.55, cz + wr * 0.55),
          Vector3(outer, wr * 1.45, cz + wr * 0.55),
          Vector3(outer, wr * 1.45, cz - wr * 0.55),
        ], rim));
      } else {
        faces.add(Face([
          Vector3(outer, wr * 0.55, cz + wr * 0.55),
          Vector3(outer, wr * 0.55, cz - wr * 0.55),
          Vector3(outer, wr * 1.45, cz - wr * 0.55),
          Vector3(outer, wr * 1.45, cz + wr * 0.55),
        ], rim));
      }
    }
  }

  return Mesh3D(faces);
}

/// A city block: walls, a roof slab and window bands on each side.
/// Every face winds outwards.
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

  // Roof slab (faces +Y).
  faces.add(Face([
    Vector3(x - w / 2 - 0.15, h + 0.05, z + d / 2 + 0.15),
    Vector3(x + w / 2 + 0.15, h + 0.05, z + d / 2 + 0.15),
    Vector3(x + w / 2 + 0.15, h + 0.05, z - d / 2 - 0.15),
    Vector3(x - w / 2 - 0.15, h + 0.05, z - d / 2 - 0.15),
  ], roof));

  final y0 = h * 0.45;
  final y1 = h * 0.8;
  const o = 0.03;
  final ix = w * 0.15;
  final iz = d * 0.15;

  // -z wall (faces -Z).
  faces.add(Face([
    Vector3(x + w / 2 - ix, y0, z - d / 2 - o),
    Vector3(x - w / 2 + ix, y0, z - d / 2 - o),
    Vector3(x - w / 2 + ix, y1, z - d / 2 - o),
    Vector3(x + w / 2 - ix, y1, z - d / 2 - o),
  ], window));

  // +z wall (faces +Z).
  faces.add(Face([
    Vector3(x - w / 2 + ix, y0, z + d / 2 + o),
    Vector3(x + w / 2 - ix, y0, z + d / 2 + o),
    Vector3(x + w / 2 - ix, y1, z + d / 2 + o),
    Vector3(x - w / 2 + ix, y1, z + d / 2 + o),
  ], window));

  // -x wall (faces -X).
  faces.add(Face([
    Vector3(x - w / 2 - o, y0, z - d / 2 + iz),
    Vector3(x - w / 2 - o, y0, z + d / 2 - iz),
    Vector3(x - w / 2 - o, y1, z + d / 2 - iz),
    Vector3(x - w / 2 - o, y1, z - d / 2 + iz),
  ], window));

  // +x wall (faces +X).
  faces.add(Face([
    Vector3(x + w / 2 + o, y0, z + d / 2 - iz),
    Vector3(x + w / 2 + o, y0, z - d / 2 + iz),
    Vector3(x + w / 2 + o, y1, z - d / 2 + iz),
    Vector3(x + w / 2 + o, y1, z + d / 2 - iz),
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

Vector3 _centroid(List<Vector3> pts) {
  var x = 0.0, y = 0.0, z = 0.0;
  for (final p in pts) {
    x += p.x;
    y += p.y;
    z += p.z;
  }
  final n = pts.length.toDouble();
  return Vector3(x / n, y / n, z / n);
}

List<_Projected> _project(List<Mesh3D> meshes, Camera3D cam, Size size) {
  final items = <_Projected>[];
  for (final mesh in meshes) {
    for (final face in mesh.faces) {
      // Back-face culling: skip faces that point away from the camera.
      if (face.points.length >= 3) {
        final a = face.points[0];
        final b = face.points[1];
        final c = face.points[2];
        final n = (b - a).cross(c - a);
        if (n.length2 > 1e-9) {
          n.normalize();
          if (n.dot(cam.position - _centroid(face.points)) < 0) continue;
        }
      }

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
  final k = 0.55 + 0.45 * n.dot(light).abs();
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
