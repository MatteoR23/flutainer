import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/theme_view_model.dart';
import 'debug_log_view.dart';
import 'license_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Tema',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const _ThemePickerCard(),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.article_outlined),
              title: const Text('Licenza (MIT)'),
              subtitle: const Text('Visualizza i termini della licenza'),
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
                title: const Text('Log applicazione'),
                subtitle: const Text('Disponibile solo in debug'),
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
              'Modalità colore',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  label: Text('Sistema'),
                  icon: Icon(Icons.brightness_auto),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  label: Text('Chiaro'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  label: Text('Scuro'),
                  icon: Icon(Icons.dark_mode),
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
