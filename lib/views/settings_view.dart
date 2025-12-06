import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/app_language_option.dart';
import '../viewmodels/locale_view_model.dart';
import '../viewmodels/theme_view_model.dart';
import 'debug_log_view.dart';
import 'license_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _ThemePickerCard(),
          const SizedBox(height: 24),
          const _LanguagePickerCard(),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.article_outlined),
              title: Text(context.l10n.licenseCardTitle),
              subtitle: Text(context.l10n.licenseCardSubtitle),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LicenseView(),
                  ),
                );
              },
            ),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.terminal),
                title: Text(context.l10n.logCardTitle),
                subtitle: Text(context.l10n.logCardSubtitle),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const DebugLogView(),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThemePickerCard extends StatelessWidget {
  const _ThemePickerCard();

  @override
  Widget build(BuildContext context) {
    final themeModel = context.watch<ThemeViewModel>();
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.themeTitle,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  label: Text(context.l10n.themeSystem),
                  icon: const Icon(Icons.brightness_auto),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  label: Text(context.l10n.themeLight),
                  icon: const Icon(Icons.light_mode),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  label: Text(context.l10n.themeDark),
                  icon: const Icon(Icons.dark_mode),
                ),
              ],
              selected: <ThemeMode>{themeModel.mode},
              onSelectionChanged: (selection) {
                final mode = selection.first;
                themeModel.setMode(mode);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguagePickerCard extends StatelessWidget {
  const _LanguagePickerCard();

  @override
  Widget build(BuildContext context) {
    final localeModel = context.watch<LocaleViewModel>();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final options = AppLanguageOption.build(l10n);

    final selectedTag = localeModel.overrideLocale?.toLanguageTag() ?? 'system';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.languageTitle,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.languageSelectLabel,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedTag,
                  isExpanded: true,
                  items: options
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option.tag,
                          child: Row(
                            children: [
                              option.flag != null
                                  ? Text(
                                      option.flag!,
                                      style: const TextStyle(fontSize: 20),
                                    )
                                  : Icon(
                                      option.icon ?? Icons.flag,
                                      size: 20,
                                    ),
                              const SizedBox(width: 8),
                              Text(option.label(l10n)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (tag) {
                    final option = options.firstWhere((opt) => opt.tag == tag);
                    localeModel.setLocale(option.locale);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
