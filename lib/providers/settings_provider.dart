import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
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

  void setDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  void setNotifications(bool value) {
    _notificationsOn = value;
    notifyListeners();
  }

  void setCurrency(String value) {
    _currency = value;
    notifyListeners();
  }

  void setProfilePhoto(String? path) {
    _profilePhotoPath = path;
    notifyListeners();
  }
}
