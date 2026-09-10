import 'package:flutter/material.dart';
import 'package:invoice_pro/core/constants/storage_keys.dart';
import 'package:invoice_pro/services/local_storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._storage) {
    _themeMode = _parse(_storage.getString(StorageKeys.themeMode));
  }

  final LocalStorageService _storage;
  late ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _storage.setString(StorageKeys.themeMode, _encode(mode));
  }

  static ThemeMode _parse(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _encode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
