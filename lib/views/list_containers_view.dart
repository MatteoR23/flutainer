import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/endpoint_credential.dart';
import '../models/portainer_container.dart';
import '../services/portainer_service.dart';
import '../viewmodels/list_containers_view_model.dart';
import 'container_log_view.dart';
import 'widgets/app_navigation_drawer.dart';

class ListContainersView extends StatelessWidget {
  const ListContainersView({
    super.key,
    required this.credential,
  });

  final EndpointCredential credential;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ListContainersViewModel>(
      create: (_) => ListContainersViewModel(
        service: PortainerService(credential: credential),
      )..initialize(),
      child: _ListContainersScaffold(currentCredential: credential),
    );
  }
}

class _ListContainersScaffold extends StatelessWidget {
  const _ListContainersScaffold({required this.currentCredential});

  final EndpointCredential currentCredential;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ListContainersViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutainer - Containers'),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Menu',
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: AppNavigationDrawer(
        currentCredentialId: currentCredential.id,
        onEndpointSelected: (credential) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => ListContainersView(credential: credential),
            ),
          );
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildBody(viewModel, context),
      ),
    );
  }

  Widget _buildBody(
      ListContainersViewModel viewModel, BuildContext context) {
    if (viewModel.isLoadingEnvironments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.environmentError != null) {
      return _ErrorState(
        message: viewModel.environmentError!,
        actionLabel: 'Riprova',
        onAction: viewModel.loadEnvironments,
      );
    }

    if (viewModel.environments.isEmpty) {
      return _ErrorState(
        message: 'Nessun environment disponibile su questo Portainer.',
        actionLabel: 'Ricarica',
        onAction: viewModel.loadEnvironments,
      );
    }

    final theme = Theme.of(context);
    final selectedEnv = viewModel.selectedEnvironment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int>(
          initialValue: selectedEnv?.id,
          decoration: const InputDecoration(
            labelText: 'Environment',
            border: OutlineInputBorder(),
          ),
          items: viewModel.environments
              .map(
                (env) => DropdownMenuItem<int>(
                  value: env.id,
                  child: Text(env.name),
                ),
              )
              .toList(),
          onChanged: viewModel.isLoadingContainers
              ? null
              : (value) {
                  if (value != null) {
                    viewModel.selectEnvironment(value);
                  }
                },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: viewModel.searchQuery,
                onChanged: viewModel.setSearchQuery,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Cerca container...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: viewModel.isLoadingContainers
                  ? null
                  : viewModel.refreshContainers,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch.adaptive(
                value: viewModel.autoRefreshEnabled,
                onChanged: viewModel.setAutoRefresh,
              ),
              const SizedBox(width: 4),
              const Text('Auto refresh'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (viewModel.containersError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              viewModel.containersError!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        Expanded(
          child: _buildContainersSection(viewModel, theme),
        ),
      ],
    );
  }

  Widget _buildContainersSection(
    ListContainersViewModel viewModel,
    ThemeData theme,
  ) {
    if (viewModel.isLoadingContainers) {
      return const Center(child: CircularProgressIndicator());
    }

    final containers = viewModel.filteredContainers;
    if (viewModel.containers.isEmpty) {
      return const _ErrorState(
        message: 'Nessun container trovato per questo environment.',
      );
    }

    if (containers.isEmpty) {
      return const _ErrorState(
        message: 'Nessun container corrisponde alla ricerca.',
      );
    }

    return ListView.separated(
      itemCount: containers.length,
      separatorBuilder: (context, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final container = containers[index];
        final environment = viewModel.selectedEnvironment;
        return _ContainerCard(
          container: container,
          viewModel: viewModel,
          onViewLogs: environment == null
              ? null
              : () => _openContainerLogs(context, container, environment.id),
        );
      },
    );
  }

  void _openContainerLogs(
    BuildContext context,
    PortainerContainer container,
    int environmentId,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ContainerLogView(
          credential: currentCredential,
          environmentId: environmentId,
          container: container,
        ),
      ),
    );
  }
}

class _ContainerCard extends StatelessWidget {
  const _ContainerCard({
    required this.container,
    required this.viewModel,
    required this.onViewLogs,
  });

  final PortainerContainer container;
  final ListContainersViewModel viewModel;
  final VoidCallback? onViewLogs;

  Color _colorForState(ContainerVisualState state, ThemeData theme) {
    switch (state) {
      case ContainerVisualState.running:
        return Colors.green.shade400;
      case ContainerVisualState.paused:
        return Colors.amber.shade700;
      case ContainerVisualState.error:
        return Colors.red.shade500;
      case ContainerVisualState.stopped:
        return Colors.grey.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stateColor = _colorForState(container.visualState, theme);
    final isBusy = viewModel.isContainerBusy(container.id);

    return Container(
      decoration: BoxDecoration(
        color: stateColor.withValues(alpha: 0.12),
        border: Border.all(color: stateColor),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  container.name,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                container.state.toUpperCase(),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: stateColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            container.statusText,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (container.canStart)
                IconButton(
                  tooltip: 'Avvia',
                  onPressed: isBusy
                      ? null
                      : () => viewModel.startContainer(container.id),
                  icon: const Icon(Icons.play_arrow),
                ),
              if (container.canStop)
                IconButton(
                  tooltip: 'Stop',
                  onPressed: isBusy
                      ? null
                      : () => viewModel.stopContainer(container.id),
                  icon: const Icon(Icons.stop),
                ),
              if (container.canPause)
                IconButton(
                  tooltip: 'Pausa',
                  onPressed: isBusy
                      ? null
                      : () => viewModel.pauseContainer(container.id),
                  icon: const Icon(Icons.pause),
                ),
              if (container.canUnpause)
                IconButton(
                  tooltip: 'Riprendi',
                  onPressed: isBusy
                      ? null
                      : () => viewModel.unpauseContainer(container.id),
                  icon: const Icon(Icons.play_circle),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onViewLogs,
              icon: const Icon(Icons.receipt_long),
              label: const Text('View log'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
