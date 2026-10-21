import 'package:flutter/foundation.dart';

import 'models/car.dart';
import 'services/storage_service.dart';

/// Holds the player's coins, unlocked cars, selected car and settings,
/// and persists them locally.
class PlayerData extends ChangeNotifier {
  final StorageService _storage = StorageService();

  int coins = 0;
  Set<String> unlocked = <String>{};
  String selectedCarId = kCars.first.id;
  bool soundOn = true;
  bool useTilt = false;

  Future<void> load() async {
    coins = await _storage.loadCoins();

    unlocked = (await _storage.loadUnlocked()).toSet();
    if (unlocked.isEmpty) {
      unlocked = <String>{kCars.first.id};
    }

    final savedSelected = await _storage.loadSelected();
    selectedCarId = savedSelected ?? kCars.first.id;
    if (!unlocked.contains(selectedCarId)) {
      selectedCarId = kCars.first.id;
    }

    soundOn = await _storage.loadSound();
    useTilt = await _storage.loadTilt();
    notifyListeners();
  }

  CarModel get selectedCar => kCars.firstWhere(
        (car) => car.id == selectedCarId,
        orElse: () => kCars.first,
      );

  bool isUnlocked(String id) => unlocked.contains(id);

  Future<void> selectCar(String id) async {
    if (!isUnlocked(id)) return;
    selectedCarId = id;
    await _storage.saveSelected(id);
    notifyListeners();
  }

  /// Returns true if the car is now unlocked.
  Future<bool> unlockCar(CarModel car) async {
    if (isUnlocked(car.id)) return true;
    if (coins < car.price) return false;
    coins -= car.price;
    unlocked.add(car.id);
    await _storage.saveCoins(coins);
    await _storage.saveUnlocked(unlocked.toList());
    notifyListeners();
    return true;
  }

  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    coins += amount;
    await _storage.saveCoins(coins);
    notifyListeners();
  }

  Future<void> setSound(bool value) async {
    soundOn = value;
    await _storage.saveSound(value);
    notifyListeners();
  }

  Future<void> setTilt(bool value) async {
    useTilt = value;
    await _storage.saveTilt(value);
    notifyListeners();
  }
}
