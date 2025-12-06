import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/endpoint_credential.dart';
import '../viewmodels/app_view_model.dart';
import 'list_containers_view.dart';

class HomePageView extends StatelessWidget {
  const HomePageView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AppViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Endpoints'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Ricarica',
            onPressed: viewModel.isLoading ? null : () => viewModel.refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCredentialDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi endpoint'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildBody(viewModel, context),
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
              viewModel.errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: viewModel.refresh,
              child: const Text('Riprova'),
            ),
          ],
        ),
      );
    }

    if (viewModel.credentials.isEmpty) {
      return Center(
        child: Text(
          'Non hai ancora configurato endpoint.\nAggiungine uno per iniziare.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      itemCount: viewModel.credentials.length,
      itemBuilder: (context, index) {
        final credential = viewModel.credentials[index];
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
                  'API key: ${_maskApiKey(credential.apiKey)}',
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
                      label: const Text('Connetti'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showCredentialDialog(
                        context,
                        credential: credential,
                      ),
                      icon: const Icon(Icons.edit),
                      label: const Text('Modifica'),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _confirmDeletion(context, credential.id),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Elimina'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 12),
    );
  }

  static String _maskApiKey(String apiKey) {
    if (apiKey.isEmpty) return '(vuota)';
    const maskChar = '*';
    if (apiKey.length <= 4) {
      return ''.padLeft(apiKey.length, maskChar);
    }
    final visible = apiKey.substring(apiKey.length - 4);
    final masked = ''.padLeft(apiKey.length - 4, maskChar);
    return '$masked$visible';
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
            ? 'Nuovo endpoint'
            : 'Modifica endpoint'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  hintText: 'Produzione, Demo...',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'URL Portainer',
                  hintText: 'https://example.it/api',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci un URL valido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API key',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci un\'API key';
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
            child: const Text('Annulla'),
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
            child: const Text('Salva'),
          ),
        ],
      );
    },
  );

  if (result == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(credential == null
            ? 'Endpoint "${nameController.text.isEmpty ? urlController.text : nameController.text}" creato'
            : 'Endpoint aggiornato'),
      ),
    );
  }
}

Future<void> _confirmDeletion(BuildContext context, String credentialId) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Elimina endpoint'),
      content: const Text(
        'Sei sicuro di voler eliminare questo endpoint? L\'operazione non è reversibile.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Elimina'),
        ),
      ],
    ),
  );

  if (!context.mounted) return;

  if (confirmed == true) {
    await context.read<AppViewModel>().deleteCredential(credentialId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Endpoint eliminato')),
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
