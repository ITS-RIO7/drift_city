import 'package:flutter/material.dart';

/// A car the player can drift in the garage.
///
/// Stats are normalised 0..1 and drive the arcade physics in the game.
/// [length], [width] and [height] are the body dimensions (world units) used
/// to build the stylised 3D model.
class CarModel {
  final String id;
  final String name;
  final Color color;
  final double speed; // top speed + acceleration
  final double grip; // how quickly the car holds a line
  final double drift; // how easily the rear steps out
  final int price; // coins to unlock, 0 = free

  final double length;
  final double width;
  final double height;

  const CarModel({
    required this.id,
    required this.name,
    required this.color,
    required this.speed,
    required this.grip,
    required this.drift,
    required this.price,
    this.length = 4.8,
    this.width = 1.9,
    this.height = 1.36,
  });

  // Physics values derived from the stats, used by the game engine.
  // Lower top speed and gentle acceleration so the car builds speed slowly
  // instead of snapping to its maximum.
  double get maxSpeed => 230 + speed * 70;
  double get enginePower => 105 + speed * 70;
  // Grip and steering are tuned so the car drives straight and only slides
  // when provoked - it should never spin out of control.
  double get gripLat => 1.9 - drift * 0.8;
  double get steerRate => 2.0 + grip * 0.6;
}

/// Both cars are free.
const List<CarModel> kCars = <CarModel>[
  CarModel(
    id: 'bmw_m8',
    name: 'BMW M8',
    color: Color(0xFF6E7176),
    speed: 0.82,
    grip: 0.74,
    drift: 0.68,
    price: 0,
    length: 4.87,
    width: 1.90,
    height: 1.36,
  ),
  CarModel(
    id: 'ford_mustang',
    name: 'Ford Mustang',
    color: Color(0xFF26282D),
    speed: 0.78,
    grip: 0.66,
    drift: 0.82,
    price: 0,
    length: 4.79,
    width: 1.92,
    height: 1.38,
  ),
];

/// Paint colours the player can apply to a car in Settings.
const List<Color> kCarPalette = <Color>[
  Color(0xFFE53935), // red
  Color(0xFF1E88E5), // blue
  Color(0xFF43A047), // green
  Color(0xFFFDD835), // yellow
  Color(0xFFFB8C00), // orange
  Color(0xFF8E24AA), // purple
  Color(0xFF00ACC1), // cyan
  Color(0xFFEC407A), // pink
  Color(0xFF2AA5A5), // teal
  Color(0xFF6D4C41), // brown
  Color(0xFFE0E0E0), // white
  Color(0xFF9E9E9E), // silver
  Color(0xFF424242), // grey
  Color(0xFF141414), // black
];
