import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/location_currency_service.dart';

class SettingsProvider extends ChangeNotifier {

  static const _keyCurrency       = 'settings_currency';
  static const _keyProfilePhoto   = 'settings_profile_photo';
  static const _keyCurrencySet    = 'settings_currency_set_by_user';

  String  _currency           = 'USD';
  String? _profilePhotoPath;

  String get currency         => _currency;
  String? get profilePhotoPath => _profilePhotoPath;

  /// Currency symbol for display — uses the extended map from LocationCurrencyService
  String get currencySymbol =>
      LocationCurrencyService.currencySymbols[_currency] ?? '$_currency ';

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _profilePhotoPath = prefs.getString(_keyProfilePhoto);

    final userHasSetCurrency = prefs.getBool(_keyCurrencySet) ?? false;

    if (userHasSetCurrency) {
      // User already manually chose a currency — honour their choice
      _currency = prefs.getString(_keyCurrency) ?? 'USD';
    } else {
      // Use locale as the instant default (no permission needed)
      _currency = prefs.getString(_keyCurrency)
          ?? LocationCurrencyService.detectCurrencyFromLocale();
    }
    notifyListeners();
  }

  /// Called from the UI (post-frame) to request location permission and
  /// upgrade the currency based on actual GPS country if not manually set.
  Future<void> triggerGPSCurrencyDetection({BuildContext? context}) async {
    final prefs = await SharedPreferences.getInstance();
    final userHasSetCurrency = prefs.getBool(_keyCurrencySet) ?? false;
    if (userHasSetCurrency) return; // user has a manual preference — skip

    if (context != null && !context.mounted) return;
    
    final gpsCurrency = await LocationCurrencyService.detectCurrencyFromLocation(context: context);
    if (gpsCurrency != null && gpsCurrency != _currency) {
      _currency = gpsCurrency;
      await prefs.setString(_keyCurrency, _currency);
      notifyListeners();
    }
  }

  /// Called when the user manually picks a currency from the UI.
  /// Sets a flag so auto-detect never overrides their choice again.
  Future<void> setCurrency(String value) async {
    _currency = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrency, value);
    await prefs.setBool(_keyCurrencySet, true); // lock auto-detect out
  }

  /// Resets the user's currency choice so auto-detect kicks in again on next launch.
  Future<void> resetCurrencyToAutoDetect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrencySet);
    await prefs.remove(_keyCurrency);
    // Re-run detection
    final gpsCurrency = await LocationCurrencyService.detectCurrencyFromLocation();
    _currency = gpsCurrency ?? LocationCurrencyService.detectCurrencyFromLocale();
    await prefs.setString(_keyCurrency, _currency);
    notifyListeners();
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
