import 'package:flutter/material.dart';

/// A car the player can drift in the garage.
///
/// Stats are normalised 0..1 and drive the arcade physics in the game.
class CarModel {
  final String id;
  final String name;
  final Color color;
  final double speed; // top speed + acceleration
  final double grip; // how quickly the car holds a line
  final double drift; // how easily the rear steps out
  final int price; // coins to unlock, 0 = starter car

  const CarModel({
    required this.id,
    required this.name,
    required this.color,
    required this.speed,
    required this.grip,
    required this.drift,
    required this.price,
  });

  // Physics values derived from the stats, used by the game engine.
  double get maxSpeed => 300 + speed * 150;
  double get enginePower => 320 + speed * 220;
  double get gripLat => 1.7 - drift * 1.05;
  double get steerRate => 2.4 + grip * 0.9;
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
  ),
  CarModel(
    id: 'bmw_e36',
    name: 'BMW E36',
    color: Color(0xFFB0B4BA),
    speed: 0.66,
    grip: 0.62,
    drift: 0.80,
    price: 800,
  ),
  CarModel(
    id: 'bmw_e46',
    name: 'BMW E46',
    color: Color(0xFF1C4FA1),
    speed: 0.68,
    grip: 0.64,
    drift: 0.78,
    price: 1200,
  ),
  CarModel(
    id: 'toyota_gr86',
    name: 'Toyota GR86',
    color: Color(0xFFD13B2E),
    speed: 0.72,
    grip: 0.74,
    drift: 0.70,
    price: 1600,
  ),
  CarModel(
    id: 'subaru_brz',
    name: 'Subaru BRZ',
    color: Color(0xFF1F6FB2),
    speed: 0.70,
    grip: 0.76,
    drift: 0.66,
    price: 1600,
  ),
  CarModel(
    id: 'silvia_s13',
    name: 'Nissan Silvia S13',
    color: Color(0xFFE0E0E0),
    speed: 0.62,
    grip: 0.58,
    drift: 0.86,
    price: 900,
  ),
  CarModel(
    id: 'silvia_s14',
    name: 'Nissan Silvia S14',
    color: Color(0xFFB58A2B),
    speed: 0.66,
    grip: 0.60,
    drift: 0.84,
    price: 1400,
  ),
  CarModel(
    id: 'silvia_s15',
    name: 'Nissan Silvia S15',
    color: Color(0xFFE05A1E),
    speed: 0.70,
    grip: 0.63,
    drift: 0.82,
    price: 2000,
  ),
  CarModel(
    id: 'mazda_rx7',
    name: 'Mazda RX-7',
    color: Color(0xFFF2C400),
    speed: 0.74,
    grip: 0.65,
    drift: 0.83,
    price: 2400,
  ),
  CarModel(
    id: 'bmw_m2',
    name: 'BMW M2 Competition',
    color: Color(0xFF2AA5A5),
    speed: 0.80,
    grip: 0.72,
    drift: 0.76,
    price: 3000,
  ),
];
