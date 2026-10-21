import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around SharedPreferences for local progress + settings.
class StorageService {
  static const String _coinsKey = 'coins';
  static const String _unlockedKey = 'unlocked_cars';
  static const String _selectedKey = 'selected_car';
  static const String _soundKey = 'sound_on';
  static const String _tiltKey = 'use_tilt';
  static const String _sensitivityKey = 'steer_sensitivity';
  static const String _buttonSizeKey = 'button_size';
  static const String _leftHandedKey = 'left_handed';
  static const String _carColorsKey = 'car_colors';

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

  Future<double> loadSensitivity() async =>
      (await _prefs).getDouble(_sensitivityKey) ?? 1.0;

  Future<void> saveSensitivity(double value) async =>
      (await _prefs).setDouble(_sensitivityKey, value);

  Future<double> loadButtonSize() async =>
      (await _prefs).getDouble(_buttonSizeKey) ?? 1.0;

  Future<void> saveButtonSize(double value) async =>
      (await _prefs).setDouble(_buttonSizeKey, value);

  Future<bool> loadLeftHanded() async =>
      (await _prefs).getBool(_leftHandedKey) ?? false;

  Future<void> saveLeftHanded(bool value) async =>
      (await _prefs).setBool(_leftHandedKey, value);

  /// Car paint overrides, stored as "carId:argb" entries.
  Future<Map<String, int>> loadCarColors() async {
    final list = (await _prefs).getStringList(_carColorsKey) ?? <String>[];
    final map = <String, int>{};
    for (final entry in list) {
      final i = entry.indexOf(':');
      if (i <= 0) continue;
      final value = int.tryParse(entry.substring(i + 1));
      if (value != null) {
        map[entry.substring(0, i)] = value;
      }
    }
    return map;
  }

  Future<void> saveCarColors(Map<String, int> colors) async {
    await (await _prefs).setStringList(
      _carColorsKey,
      colors.entries.map((e) => '${e.key}:${e.value}').toList(),
    );
  }
}
