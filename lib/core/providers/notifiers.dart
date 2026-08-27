import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notifier pour l'état de l'onboarding
class OnboardingNotifier extends ValueNotifier<bool> {
  OnboardingNotifier(super.value);
}

/// Notifier pour l'état d'authentification
class AuthNotifier extends ValueNotifier<bool> {
  AuthNotifier(super.value);
}

/// Notifier pour la langue de l'application
class LocaleNotifier extends ValueNotifier<Locale?> {
  LocaleNotifier(super.value);

  static const String storageKey = 'app_locale';

  static Future<Locale?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(storageKey);
    if (languageCode == null || languageCode.isEmpty) {
      return null;
    }
    return Locale(languageCode);
  }

  Future<void> updateLocale(Locale? locale) async {
    value = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(storageKey);
    } else {
      await prefs.setString(storageKey, locale.languageCode);
    }
  }
}
