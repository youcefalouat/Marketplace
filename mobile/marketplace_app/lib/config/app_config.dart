import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppConfig {
  static const String _apiBaseUrlFromDartDefine =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String? _apiBaseUrlFromAsset;

  static Future<void> load() async {
    try {
      final raw =
          await rootBundle.loadString('assets/config/app_config.json');
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final value = (decoded['apiBaseUrl'] as String?) ?? '';
        _apiBaseUrlFromAsset = _normalizeApiBaseUrl(value);
      }
    } catch (_) {
      _apiBaseUrlFromAsset = null;
    }
  }

  static String get apiBaseUrl {
    final configured = _normalizeApiBaseUrl(_apiBaseUrlFromDartDefine);
    if (configured.isNotEmpty) return configured;

    final assetValue = _apiBaseUrlFromAsset ?? '';
    if (assetValue.isNotEmpty) return assetValue;

    return _platformFallbackApiBaseUrl();
  }

  static String _platformFallbackApiBaseUrl() {
    if (kIsWeb) return 'http://localhost:5000/api';

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }

    return 'http://localhost:5000/api';
  }

  static String _normalizeApiBaseUrl(String value) {
    var normalized = value.trim();
    if (normalized.isEmpty) return '';

    normalized = normalized.replaceAll(RegExp(r'/+$'), '');

    if (!normalized.endsWith('/api')) {
      normalized = '$normalized/api';
    }

    return normalized;
  }
}
