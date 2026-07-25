import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _keyDarkMode = 'settings_dark_mode';
  static const _keyNotifications = 'settings_notifications';
  static const _keyCurrency = 'settings_currency';
  static const _keyProfilePhoto = 'settings_profile_photo';

  bool _isDarkMode = false;
  bool _notificationsOn = true;
  String _currency = 'PKR';
  String? _profilePhotoPath;

  bool get isDarkMode => _isDarkMode;
  bool get notificationsOn => _notificationsOn;
  String get currency => _currency;
  String? get profilePhotoPath => _profilePhotoPath;

  /// Currency symbol for display (e.g. "Rs" for PKR, "$" for USD)
  String get currencySymbol {
    const map = {
      'PKR': 'Rs ',
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'AED': 'AED ',
      'SAR': 'SAR ',
      'INR': '₹',
    };
    return map[_currency] ?? '$_currency ';
  }

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_keyDarkMode) ?? false;
    _notificationsOn = prefs.getBool(_keyNotifications) ?? true;
    _currency = prefs.getString(_keyCurrency) ?? 'PKR';
    _profilePhotoPath = prefs.getString(_keyProfilePhoto);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  Future<void> setNotifications(bool value) async {
    _notificationsOn = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
  }

  Future<void> setCurrency(String value) async {
    _currency = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrency, value);
  }

  Future<void> setProfilePhoto(String? path) async {
    _profilePhotoPath = path;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_keyProfilePhoto);
    } else {
      await prefs.setString(_keyProfilePhoto, path);
    }
  }
}
