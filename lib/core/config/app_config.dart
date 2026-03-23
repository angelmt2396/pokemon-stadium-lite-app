import 'dart:io';

import 'package:flutter/foundation.dart';

class AppConfig {
  static const _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const _socketBaseUrlOverride = String.fromEnvironment(
    'SOCKET_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl =>
      _apiBaseUrlOverride.isNotEmpty ? _apiBaseUrlOverride : _defaultLocalBaseUrl;

  static String get socketBaseUrl =>
      _socketBaseUrlOverride.isNotEmpty ? _socketBaseUrlOverride : _defaultLocalBaseUrl;

  static String get _defaultLocalBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }

    return 'http://localhost:3000';
  }
}
