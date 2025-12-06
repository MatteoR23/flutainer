import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/endpoint_credential.dart';
import '../../viewmodels/app_view_model.dart';
import '../settings_view.dart';

class AppNavigationDrawer extends StatelessWidget {
  const AppNavigationDrawer({
    super.key,
    this.currentCredentialId,
    this.onEndpointSelected,
  });

  final String? currentCredentialId;
  final ValueChanged<EndpointCredential>? onEndpointSelected;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AppViewModel>();
    final credentials = viewModel.credentials;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _DrawerHeader(),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home Page'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            if (credentials.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Endpoints',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            if (credentials.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: credentials.length,
                  itemBuilder: (context, index) {
                    final credential = credentials[index];
                    return ListTile(
                      leading: const Icon(Icons.cloud_outlined),
                      title: Text(
                        credential.name.isEmpty
                            ? credential.url
                            : credential.name,
                      ),
                      subtitle: Text(credential.url),
                      selected: credential.id == currentCredentialId,
                      onTap: () {
                        Navigator.of(context).pop();
                        if (credential.id == currentCredentialId) return;
                        onEndpointSelected?.call(credential);
                      },
                    );
                  },
                ),
              )
            else
              const Expanded(
                child: Center(
                  child: Text(
                    'Nessun endpoint configurato',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text('Impostazioni'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsView(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              Icons.anchor,
              size: 48,
              color: theme.colorScheme.onPrimary,
            ),
            const SizedBox(height: 8),
            Text(
              'Flutainer',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Portainer companion',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
