import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Resolves the user's country and maps it to an ISO 4217 currency code.
///
/// Detection strategy (in priority order):
///   1. GPS coordinates → bounding-box country lookup (pure Dart, no HTTP)
///   2. Device locale country code (instant, no permission needed)
///   3. Hardcoded default 'USD'
class LocationCurrencyService {
  // ── Country → Currency mapping (ISO 3166-1 alpha-2 → ISO 4217) ────────────
  static const Map<String, String> _countryCurrencyMap = {
    // South Asia
    'IN': 'INR', 'PK': 'PKR', 'BD': 'BDT', 'LK': 'LKR', 'NP': 'NPR',
    // Middle East
    'AE': 'AED', 'SA': 'SAR', 'QA': 'QAR', 'KW': 'KWD', 'BH': 'BHD',
    'OM': 'OMR', 'JO': 'JOD', 'EG': 'EGP', 'TR': 'TRY', 'IL': 'ILS',
    // Americas
    'US': 'USD', 'CA': 'CAD', 'MX': 'MXN', 'BR': 'BRL', 'AR': 'ARS',
    'CO': 'COP', 'CL': 'CLP', 'PE': 'PEN',
    // Europe (Eurozone)
    'DE': 'EUR', 'FR': 'EUR', 'ES': 'EUR', 'IT': 'EUR', 'NL': 'EUR',
    'BE': 'EUR', 'AT': 'EUR', 'IE': 'EUR', 'FI': 'EUR', 'PT': 'EUR',
    'GR': 'EUR', 'LU': 'EUR', 'SK': 'EUR', 'SI': 'EUR', 'EE': 'EUR',
    'LV': 'EUR', 'LT': 'EUR', 'MT': 'EUR', 'CY': 'EUR', 'HR': 'EUR',
    // Europe (Non-Eurozone)
    'GB': 'GBP', 'CH': 'CHF', 'NO': 'NOK', 'SE': 'SEK', 'DK': 'DKK',
    'PL': 'PLN', 'CZ': 'CZK', 'HU': 'HUF', 'RO': 'RON', 'BG': 'BGN',
    'RU': 'RUB', 'UA': 'UAH',
    // Asia-Pacific
    'CN': 'CNY', 'JP': 'JPY', 'KR': 'KRW', 'AU': 'AUD', 'NZ': 'NZD',
    'SG': 'SGD', 'HK': 'HKD', 'TW': 'TWD', 'TH': 'THB', 'MY': 'MYR',
    'ID': 'IDR', 'PH': 'PHP', 'VN': 'VND',
    // Africa
    'ZA': 'ZAR', 'NG': 'NGN', 'KE': 'KES', 'GH': 'GHS', 'TZ': 'TZS',
    'ET': 'ETB', 'MA': 'MAD',
  };

  /// Bounding boxes for common countries: [minLat, maxLat, minLng, maxLng]
  /// Used to derive country from GPS coordinates without reverse geocoding.
  static const List<Map<String, dynamic>> _countryBounds = [
    {'code': 'IN', 'minLat':  6.0, 'maxLat': 37.0, 'minLng': 68.0, 'maxLng': 97.5},
    {'code': 'PK', 'minLat': 23.5, 'maxLat': 37.1, 'minLng': 60.8, 'maxLng': 77.8},
    {'code': 'BD', 'minLat': 20.6, 'maxLat': 26.6, 'minLng': 88.0, 'maxLng': 92.7},
    {'code': 'AE', 'minLat': 22.6, 'maxLat': 26.1, 'minLng': 51.6, 'maxLng': 56.4},
    {'code': 'SA', 'minLat': 16.4, 'maxLat': 32.2, 'minLng': 36.5, 'maxLng': 55.7},
    {'code': 'QA', 'minLat': 24.5, 'maxLat': 26.2, 'minLng': 50.7, 'maxLng': 51.7},
    {'code': 'KW', 'minLat': 28.5, 'maxLat': 30.1, 'minLng': 46.5, 'maxLng': 48.4},
    {'code': 'BH', 'minLat': 25.8, 'maxLat': 26.3, 'minLng': 50.4, 'maxLng': 50.7},
    {'code': 'OM', 'minLat': 16.6, 'maxLat': 26.4, 'minLng': 51.8, 'maxLng': 59.9},
    {'code': 'JO', 'minLat': 29.2, 'maxLat': 33.4, 'minLng': 34.9, 'maxLng': 39.3},
    {'code': 'EG', 'minLat': 22.0, 'maxLat': 31.7, 'minLng': 25.0, 'maxLng': 37.1},
    {'code': 'TR', 'minLat': 35.8, 'maxLat': 42.1, 'minLng': 26.0, 'maxLng': 44.8},
    {'code': 'US', 'minLat': 24.4, 'maxLat': 71.4, 'minLng': -179.2, 'maxLng': -66.9},
    {'code': 'CA', 'minLat': 41.7, 'maxLat': 83.1, 'minLng': -141.0, 'maxLng': -52.6},
    {'code': 'MX', 'minLat': 14.5, 'maxLat': 32.7, 'minLng': -117.1, 'maxLng': -86.7},
    {'code': 'BR', 'minLat': -33.8, 'maxLat':  5.3, 'minLng': -73.9, 'maxLng': -28.8},
    {'code': 'AR', 'minLat': -55.1, 'maxLat': -21.8, 'minLng': -73.6, 'maxLng': -53.6},
    {'code': 'GB', 'minLat': 49.9, 'maxLat': 60.9, 'minLng': -8.6, 'maxLng':  1.8},
    {'code': 'DE', 'minLat': 47.3, 'maxLat': 55.1, 'minLng':  6.0, 'maxLng': 15.0},
    {'code': 'FR', 'minLat': 41.3, 'maxLat': 51.1, 'minLng': -5.1, 'maxLng':  9.6},
    {'code': 'IT', 'minLat': 35.5, 'maxLat': 47.1, 'minLng':  6.6, 'maxLng': 18.5},
    {'code': 'ES', 'minLat': 36.0, 'maxLat': 43.8, 'minLng': -9.3, 'maxLng':  4.3},
    {'code': 'RU', 'minLat': 41.2, 'maxLat': 81.9, 'minLng': 19.6, 'maxLng': 180.0},
    {'code': 'CN', 'minLat': 18.2, 'maxLat': 53.6, 'minLng': 73.5, 'maxLng': 134.8},
    {'code': 'JP', 'minLat': 24.0, 'maxLat': 45.6, 'minLng': 122.9, 'maxLng': 153.9},
    {'code': 'KR', 'minLat': 33.1, 'maxLat': 38.6, 'minLng': 124.6, 'maxLng': 129.6},
    {'code': 'AU', 'minLat': -43.7, 'maxLat': -10.7, 'minLng': 113.3, 'maxLng': 153.6},
    {'code': 'NZ', 'minLat': -47.3, 'maxLat': -34.4, 'minLng': 166.4, 'maxLng': 178.6},
    {'code': 'SG', 'minLat':  1.2, 'maxLat':  1.5, 'minLng': 103.6, 'maxLng': 104.0},
    {'code': 'MY', 'minLat':  0.8, 'maxLat':  7.4, 'minLng': 99.6, 'maxLng': 119.3},
    {'code': 'ID', 'minLat': -11.0, 'maxLat':  5.9, 'minLng': 95.0, 'maxLng': 141.0},
    {'code': 'TH', 'minLat':  5.6, 'maxLat': 20.5, 'minLng': 97.3, 'maxLng': 105.6},
    {'code': 'ZA', 'minLat': -34.8, 'maxLat': -22.1, 'minLng': 16.5, 'maxLng': 32.9},
    {'code': 'NG', 'minLat':  4.3, 'maxLat': 13.9, 'minLng':  2.7, 'maxLng': 14.7},
    {'code': 'KE', 'minLat': -4.7, 'maxLat':  4.6, 'minLng': 33.9, 'maxLng': 41.9},
    {'code': 'MA', 'minLat': 27.7, 'maxLat': 35.9, 'minLng': -13.2, 'maxLng': -0.9},
  ];

  /// Currency display symbols for all supported currencies
  static const Map<String, String> currencySymbols = {
    'USD': '\$',    'EUR': '€',    'GBP': '£',    'INR': '₹',
    'PKR': 'Rs ',  'AED': 'د.إ ', 'SAR': '﷼ ',  'QAR': '﷼ ',
    'KWD': 'KD ',  'BHD': 'BD ',  'OMR': 'ر.ع ', 'JOD': 'JD ',
    'EGP': 'E£ ',  'TRY': '₺',    'ILS': '₪',    'CAD': 'C\$',
    'MXN': 'Mex\$','BRL': 'R\$',  'ARS': 'ARS\$','COP': 'COL\$',
    'CLP': 'CLP\$','PEN': 'S/ ',  'CHF': 'CHF ', 'NOK': 'kr ',
    'SEK': 'kr ',  'DKK': 'kr ',  'PLN': 'zł ',  'CZK': 'Kč ',
    'HUF': 'Ft ',  'RON': 'lei ', 'BGN': 'лв ',  'RUB': '₽',
    'UAH': '₴',    'CNY': '¥',    'JPY': '¥',    'KRW': '₩',
    'AUD': 'A\$',  'NZD': 'NZ\$', 'SGD': 'S\$',  'HKD': 'HK\$',
    'TWD': 'NT\$', 'THB': '฿',    'MYR': 'RM ',  'IDR': 'Rp ',
    'PHP': '₱',    'VND': '₫',    'ZAR': 'R ',   'NGN': '₦',
    'KES': 'KSh ', 'GHS': 'GH₵ ', 'BDT': '৳',   'LKR': 'Rs ',
    'NPR': 'रू ',  'MAD': 'MAD ', 'TZS': 'TSh ', 'ETB': 'Br ',
  };

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Detects currency from GPS coordinates (pure Dart bounding-box lookup).
  /// Requests location permission, gets coordinates, maps to country & currency.
  /// Returns null if permission is denied or location unavailable.
  static Future<String?> detectCurrencyFromLocation({BuildContext? context}) async {
    try {
      // 1. Check location service availability
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationCurrencyService] Location services disabled.');
        if (context != null && context.mounted) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1C222E),
              title: const Text('Location Disabled', style: TextStyle(color: Colors.white)),
              content: const Text('Please enable location services to automatically detect your local currency.', style: TextStyle(color: Colors.white70)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Geolocator.openLocationSettings();
                  },
                  child: const Text('Open Settings', style: TextStyle(color: Color(0xFF1663FF))),
                ),
              ],
            ),
          );
        }
        return null;
      }

      // 2. Request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[LocationCurrencyService] Permission denied.');
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LocationCurrencyService] Permission permanently denied.');
        return null;
      }

      // 3. Get coarse GPS position (fast, sufficient for country detection)
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // 4. Country lookup via bounding boxes (pure Dart, no network needed)
      final countryCode = _countryFromCoordinates(
        position.latitude,
        position.longitude,
      );
      debugPrint('[LocationCurrencyService] GPS country: $countryCode '
          '(${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)})');

      if (countryCode == null) return null;
      return _countryCurrencyMap[countryCode];
    } catch (e) {
      debugPrint('[LocationCurrencyService] Error: $e');
      return null;
    }
  }

  /// Instant fallback: detect currency from device locale (no permission needed).
  static String detectCurrencyFromLocale() {
    try {
      final locale = PlatformDispatcher.instance.locale;
      final country = locale.countryCode?.toUpperCase() ?? '';
      return _countryCurrencyMap[country] ?? 'USD';
    } catch (_) {
      return 'USD';
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Maps GPS coordinates to an ISO 3166-1 alpha-2 country code using
  /// bounding box matching (pure Dart, no reverse geocoding API needed).
  static String? _countryFromCoordinates(double lat, double lng) {
    for (final entry in _countryBounds) {
      if (lat >= (entry['minLat'] as num) &&
          lat <= (entry['maxLat'] as num) &&
          lng >= (entry['minLng'] as num) &&
          lng <= (entry['maxLng'] as num)) {
        return entry['code'] as String;
      }
    }
    return null; // coordinate didn't match any known bounding box
  }
}
