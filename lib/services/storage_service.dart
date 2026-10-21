import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around SharedPreferences for local progress.
class StorageService {
  static const String _coinsKey = 'coins';
  static const String _unlockedKey = 'unlocked_cars';
  static const String _selectedKey = 'selected_car';
  static const String _soundKey = 'sound_on';
  static const String _tiltKey = 'use_tilt';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<int> loadCoins() async => (await _prefs).getInt(_coinsKey) ?? 0;

  Future<void> saveCoins(int value) async =>
      (await _prefs).setInt(_coinsKey, value);

  Future<List<String>> loadUnlocked() async =>
      (await _prefs).getStringList(_unlockedKey) ?? <String>[];

  Future<void> saveUnlocked(List<String> value) async =>
      (await _prefs).setStringList(_unlockedKey, value);

  Future<String?> loadSelected() async => (await _prefs).getString(_selectedKey);

  Future<void> saveSelected(String id) async =>
      (await _prefs).setString(_selectedKey, id);

  Future<bool> loadSound() async => (await _prefs).getBool(_soundKey) ?? true;

  Future<void> saveSound(bool value) async =>
      (await _prefs).setBool(_soundKey, value);

  Future<bool> loadTilt() async => (await _prefs).getBool(_tiltKey) ?? false;

  Future<void> saveTilt(bool value) async =>
      (await _prefs).setBool(_tiltKey, value);
}
