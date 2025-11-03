import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SettingsService with ChangeNotifier {
  final Box _settingsBox;

  // --- All app settings ---
  late bool _isDarkMode;
  late bool _autoDeleteProgress;
  late bool _autoDeleteMoney;
  late String _characterName;
  late String? _userName;
  late String? _userDOB;

  // Load all settings when the app starts
  SettingsService(this._settingsBox) {
    _isDarkMode = _settingsBox.get('isDarkMode', defaultValue: false);
    _autoDeleteProgress = _settingsBox.get('autoDeleteProgress', defaultValue: false);
    _autoDeleteMoney = _settingsBox.get('autoDeleteMoney', defaultValue: false);
    _characterName = _settingsBox.get('characterName', defaultValue: 'Fox'); // Default
    _userName = _settingsBox.get('userName');
    _userDOB = _settingsBox.get('userDOB');
  }

  // --- Theme Settings ---
  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    _settingsBox.put('isDarkMode', isDark);
    notifyListeners();
  }

  // --- Progress Data Settings ---
  bool get autoDeleteProgress => _autoDeleteProgress;
  void setAutoDeleteProgress(bool value) {
    _autoDeleteProgress = value;
    _settingsBox.put('autoDeleteProgress', value);
    notifyListeners();
  }

  // --- Money Data Settings ---
  bool get autoDeleteMoney => _autoDeleteMoney;
  void setAutoDeleteMoney(bool value) {
    _autoDeleteMoney = value;
    _settingsBox.put('autoDeleteMoney', value);
    notifyListeners();
  }

  // --- Personalization Settings ---
  String? get userName => _userName;
  String? get userDOB => _userDOB;

  // --- THIS IS THE FIX ---
  String get characterName => _characterName;
  // --- END FIX ---

  Future<void> savePersonalInfo(String name, String dob) async {
    _userName = name;
    _userDOB = dob;
    await _settingsBox.put('userName', name);
    await _settingsBox.put('userDOB', dob);
    notifyListeners();
  }

  void setCharacter(String name) {
    _characterName = name;
    _settingsBox.put('characterName', name);
    notifyListeners();
  }
}