import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localeStorageKey = 'pokemon_stadium_lite_locale';

class AppLocaleController extends Notifier<Locale> {
  bool _didBootstrap = false;

  @override
  Locale build() {
    if (!_didBootstrap) {
      _didBootstrap = true;
      Future<void>.microtask(_restore);
    }

    return const Locale('es');
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_localeStorageKey);
    if (value == null || value.isEmpty) {
      return;
    }

    state = Locale(value);
  }

  Future<void> setLocale(String languageCode) async {
    if (state.languageCode == languageCode) {
      return;
    }

    state = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeStorageKey, languageCode);
  }
}

final appLocaleControllerProvider =
    NotifierProvider<AppLocaleController, Locale>(AppLocaleController.new);

