import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

class LocaleViewModel extends ChangeNotifier {
  LocaleViewModel() {
    _systemLocale = _detectSystemLocale();
    _loadOverride();
  }

  static const String _prefsKey = 'selected_locale';

  Locale _systemLocale = const Locale('en');
  Locale? _overrideLocale;

  Locale get locale => _overrideLocale ?? _systemLocale;
  Locale? get overrideLocale => _overrideLocale;

  Future<void> setLocale(Locale? locale) async {
    if (locale != null && !_isSupported(locale)) return;
    _overrideLocale = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, locale.toLanguageTag());
    }
    notifyListeners();
  }

  Locale _detectSystemLocale() {
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    for (final locale in dispatcher.locales) {
      if (_isSupported(locale)) {
        return Locale(locale.languageCode, locale.countryCode);
      }
    }
    if (Platform.isLinux) {
      for (final key in const ['LC_ALL', 'LC_MESSAGES', 'LANG']) {
        final candidate = _localeFromTag(Platform.environment[key]);
        if (candidate != null && _isSupported(candidate)) {
          return candidate;
        }
      }
    }
    return const Locale('en');
  }

  Future<void> _loadOverride() async {
    final prefs = await SharedPreferences.getInstance();
    final tag = prefs.getString(_prefsKey);
    final locale = _localeFromTag(tag);
    if (locale != null && _isSupported(locale)) {
      _overrideLocale = locale;
      notifyListeners();
    }
  }

  bool _isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) =>
          supported.languageCode == locale.languageCode &&
          (supported.countryCode == null ||
              supported.countryCode == locale.countryCode),
    );
  }

  Locale? _localeFromTag(String? tag) {
    if (tag == null || tag.isEmpty) return null;
    final clean = tag.split('.').first.replaceAll('_', '-');
    final parts = clean.split('-');
    if (parts.isEmpty) return null;
    final language = parts[0];
    if (language.isEmpty) return null;
    final country = parts.length > 1 ? parts[1] : null;
    return Locale(language, country);
  }
}
