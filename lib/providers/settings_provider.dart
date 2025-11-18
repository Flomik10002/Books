import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  Timer? _themeChangeTimer;
  
  SettingsProvider(this._prefs) {
    _loadSettings();
  }
  
  @override
  void dispose() {
    _themeChangeTimer?.cancel();
    super.dispose();
  }

  // Theme
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  // Reading preferences
  double _fontSize = 16.0;
  double get fontSize => _fontSize;

  double _brightness = 1.0;
  double get brightness => _brightness;

  bool _keepScreenOn = true;
  bool get keepScreenOn => _keepScreenOn;

  // Sorting
  BookSortType _sortType = BookSortType.dateAdded;
  BookSortType get sortType => _sortType;

  bool _sortAscending = false;
  bool get sortAscending => _sortAscending;

  void _loadSettings() {
    // Theme
    final themeIndex = _prefs.getInt('theme_mode') ?? 0;
    _themeMode = ThemeMode.values[themeIndex];

    // Reading settings
    _fontSize = (_prefs.getDouble('font_size') ?? 16.0).clamp(12.0, 24.0);
    _brightness = (_prefs.getDouble('brightness') ?? 1.0).clamp(0.3, 1.0);
    _keepScreenOn = _prefs.getBool('keep_screen_on') ?? true;

    // Sorting
    final sortIndex = _prefs.getInt('sort_type') ?? 0;
    _sortType = BookSortType.values[sortIndex];
    _sortAscending = _prefs.getBool('sort_ascending') ?? false;

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    _themeMode = themeMode;
    await _prefs.setInt('theme_mode', themeMode.index);
    
    // Отменить предыдущий таймер для предотвращения множественных rebuilds
    _themeChangeTimer?.cancel();
    
    // Debounce для предотвращения race condition при быстрой смене темы
    _themeChangeTimer = Timer(const Duration(milliseconds: 150), () {
      notifyListeners();
    });
  }

  Future<void> setFontSize(double fontSize) async {
    _fontSize = fontSize.clamp(12.0, 24.0);
    await _prefs.setDouble('font_size', _fontSize);
    notifyListeners();
  }

  Future<void> setBrightness(double brightness) async {
    _brightness = brightness.clamp(0.3, 1.0);
    await _prefs.setDouble('brightness', _brightness);
    notifyListeners();
  }

  Future<void> setKeepScreenOn(bool keepScreenOn) async {
    _keepScreenOn = keepScreenOn;
    await _prefs.setBool('keep_screen_on', keepScreenOn);
    notifyListeners();
  }

  Future<void> setSortType(BookSortType sortType) async {
    _sortType = sortType;
    await _prefs.setInt('sort_type', sortType.index);
    notifyListeners();
  }

  Future<void> setSortAscending(bool ascending) async {
    _sortAscending = ascending;
    await _prefs.setBool('sort_ascending', ascending);
    notifyListeners();
  }
}

enum BookSortType {
  name,
  dateAdded,
  progress,
  author,
}