import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/endpoint_credential.dart';
import '../viewmodels/app_view_model.dart';
import 'list_containers_view.dart';
import 'widgets/app_navigation_drawer.dart';

class HomePageView extends StatelessWidget {
  const HomePageView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AppViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.endpointsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: context.l10n.refreshTooltip,
            onPressed: viewModel.isLoading ? null : () => viewModel.refresh(),
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              tooltip: context.l10n.menuTooltip,
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: AppNavigationDrawer(
        onEndpointSelected: (credential) =>
            _connectToEndpoint(context, credential),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCredentialDialog(context),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.addEndpoint),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const _FlutainerHero(),
            const SizedBox(height: 20),
            Expanded(child: _buildBody(viewModel, context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppViewModel viewModel, BuildContext context) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.l10n
                  .credentialsLoadError(viewModel.errorMessage ?? ''),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: viewModel.refresh,
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      );
    }

    if (viewModel.credentials.isEmpty) {
      return Center(
        child: Text(
          context.l10n.noEndpointsMessage,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      itemCount: viewModel.credentials.length,
      itemBuilder: (context, index) {
        final credential = viewModel.credentials[index];
        return _EndpointCard(credential: credential);
      },
      separatorBuilder: (context, index) => const SizedBox(height: 12),
    );
  }

}

Future<void> _showCredentialDialog(
  BuildContext context, {
  EndpointCredential? credential,
}) async {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: credential?.name ?? '');
  final urlController = TextEditingController(text: credential?.url ?? '');
  final apiKeyController =
      TextEditingController(text: credential?.apiKey ?? '');
  final viewModel = context.read<AppViewModel>();

  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(credential == null
            ? context.l10n.newEndpointTitle
            : context.l10n.editEndpointTitle),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: context.l10n.nameFieldLabel,
                  hintText: context.l10n.nameFieldHint,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: context.l10n.urlFieldLabel,
                  hintText: context.l10n.urlFieldHint,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.l10n.urlFieldError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: apiKeyController,
                decoration: InputDecoration(
                  labelText: context.l10n.apiKeyFieldLabel,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.l10n.apiKeyFieldError;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.dialogCancel),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState?.validate() != true) return;
              if (credential == null) {
                await viewModel.addCredential(
                  url: urlController.text,
                  apiKey: apiKeyController.text,
                  name: nameController.text,
                );
              } else {
                await viewModel.updateCredential(
                  credential.id,
                  url: urlController.text,
                  apiKey: apiKeyController.text,
                  name: nameController.text,
                );
              }
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
            child: Text(context.l10n.dialogSave),
          ),
        ],
      );
    },
  );

  if (result == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(credential == null
            ? context.l10n.endpointCreated(
                nameController.text.isEmpty
                    ? urlController.text
                    : nameController.text,
              )
            : context.l10n.endpointUpdated),
      ),
    );
  }
}

Future<void> _confirmDeletion(BuildContext context, String credentialId) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.l10n.deleteEndpointTitle),
      content: Text(
        context.l10n.deleteEndpointMessage,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.l10n.dialogCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(context.l10n.deleteAction),
        ),
      ],
    ),
  );

  if (!context.mounted) return;

  if (confirmed == true) {
    await context.read<AppViewModel>().deleteCredential(credentialId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.endpointDeleted)),
    );
  }
}

void _connectToEndpoint(
  BuildContext context,
  EndpointCredential credential,
) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ListContainersView(credential: credential),
    ),
  );
}

class _FlutainerHero extends StatelessWidget {
  const _FlutainerHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withAlpha((0.3 * 255).round()),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary
                  .withAlpha((0.15 * 255).round()),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.directions_boat_filled,
                size: 56,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.heroTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.heroSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EndpointCard extends StatelessWidget {
  const _EndpointCard({required this.credential});

  final EndpointCredential credential;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              credential.name.isEmpty ? credential.url : credential.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 2),
            Text(
              credential.url,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.apiKeyLabel(
                credential.apiKey.isEmpty
                    ? context.l10n.emptyValue
                    : _maskApiKey(credential.apiKey),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _connectToEndpoint(context, credential),
                  icon: const Icon(Icons.podcasts),
                  label: Text(context.l10n.connectAction),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showCredentialDialog(
                    context,
                    credential: credential,
                  ),
                  icon: const Icon(Icons.edit),
                  label: Text(context.l10n.editAction),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDeletion(context, credential.id),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(context.l10n.removeAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _maskApiKey(String apiKey) {
  if (apiKey.isEmpty) return '(vuota)';
  const maskChar = '*';
  if (apiKey.length <= 4) {
    return ''.padLeft(apiKey.length, maskChar);
  }
  final visible = apiKey.substring(apiKey.length - 4);
  final masked = ''.padLeft(apiKey.length - 4, maskChar);
  return '$masked$visible';
}
