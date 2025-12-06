import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class AppLanguageOption {
  const AppLanguageOption._({
    required this.tag,
    required this.locale,
    required this.labelBuilder,
    this.flag,
    this.icon,
  });

  final String tag;
  final Locale? locale;
  final String? flag;
  final IconData? icon;
  final String Function(AppLocalizations) labelBuilder;

  String label(AppLocalizations l10n) => labelBuilder(l10n);

  static List<AppLanguageOption> build(AppLocalizations l10n) => [
        AppLanguageOption._(
          tag: 'system',
          locale: null,
          icon: Icons.language,
          labelBuilder: (localizations) => localizations.languageSystemDefault,
        ),
        AppLanguageOption._(
          tag: 'en',
          locale: const Locale('en'),
          flag: '🇺🇸',
          labelBuilder: (localizations) => localizations.languageEnglish,
        ),
        AppLanguageOption._(
          tag: 'it',
          locale: const Locale('it'),
          flag: '🇮🇹',
          labelBuilder: (localizations) => localizations.languageItalian,
        ),
        AppLanguageOption._(
          tag: 'es',
          locale: const Locale('es'),
          flag: '🇪🇸',
          labelBuilder: (localizations) => localizations.languageSpanish,
        ),
        AppLanguageOption._(
          tag: 'pt',
          locale: const Locale('pt'),
          flag: '🇵🇹',
          labelBuilder: (localizations) => localizations.languagePortuguese,
        ),
        AppLanguageOption._(
          tag: 'de',
          locale: const Locale('de'),
          flag: '🇩🇪',
          labelBuilder: (localizations) => localizations.languageGerman,
        ),
      ];
}
