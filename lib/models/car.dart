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
  final int price; // coins to unlock, 0 = starter car

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
    this.length = 4.4,
    this.width = 1.8,
    this.height = 1.28,
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

const List<CarModel> kCars = <CarModel>[
  CarModel(
    id: 'nissan_350z',
    name: 'Nissan 350Z',
    color: Color(0xFF2E7DD1),
    speed: 0.70,
    grip: 0.66,
    drift: 0.72,
    price: 0,
    length: 4.31,
    width: 1.82,
    height: 1.28,
  ),
  CarModel(
    id: 'bmw_e36',
    name: 'BMW E36',
    color: Color(0xFFB0B4BA),
    speed: 0.66,
    grip: 0.62,
    drift: 0.80,
    price: 800,
    length: 4.43,
    width: 1.71,
    height: 1.35,
  ),
  CarModel(
    id: 'bmw_e46',
    name: 'BMW E46',
    color: Color(0xFF1C4FA1),
    speed: 0.68,
    grip: 0.64,
    drift: 0.78,
    price: 1200,
    length: 4.47,
    width: 1.74,
    height: 1.38,
  ),
  CarModel(
    id: 'toyota_gr86',
    name: 'Toyota GR86',
    color: Color(0xFFD13B2E),
    speed: 0.72,
    grip: 0.74,
    drift: 0.70,
    price: 1600,
    length: 4.26,
    width: 1.78,
    height: 1.31,
  ),
  CarModel(
    id: 'subaru_brz',
    name: 'Subaru BRZ',
    color: Color(0xFF1F6FB2),
    speed: 0.70,
    grip: 0.76,
    drift: 0.66,
    price: 1600,
    length: 4.24,
    width: 1.78,
    height: 1.29,
  ),
  CarModel(
    id: 'silvia_s13',
    name: 'Nissan Silvia S13',
    color: Color(0xFFE0E0E0),
    speed: 0.62,
    grip: 0.58,
    drift: 0.86,
    price: 900,
    length: 4.47,
    width: 1.69,
    height: 1.29,
  ),
  CarModel(
    id: 'silvia_s14',
    name: 'Nissan Silvia S14',
    color: Color(0xFFB58A2B),
    speed: 0.66,
    grip: 0.60,
    drift: 0.84,
    price: 1400,
    length: 4.52,
    width: 1.73,
    height: 1.29,
  ),
  CarModel(
    id: 'silvia_s15',
    name: 'Nissan Silvia S15',
    color: Color(0xFFE05A1E),
    speed: 0.70,
    grip: 0.63,
    drift: 0.82,
    price: 2000,
    length: 4.45,
    width: 1.73,
    height: 1.29,
  ),
  CarModel(
    id: 'mazda_rx7',
    name: 'Mazda RX-7',
    color: Color(0xFFF2C400),
    speed: 0.74,
    grip: 0.65,
    drift: 0.83,
    price: 2400,
    length: 4.28,
    width: 1.76,
    height: 1.23,
  ),
  CarModel(
    id: 'bmw_m2',
    name: 'BMW M2 Competition',
    color: Color(0xFF2AA5A5),
    speed: 0.80,
    grip: 0.72,
    drift: 0.76,
    price: 3000,
    length: 4.46,
    width: 1.85,
    height: 1.41,
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
