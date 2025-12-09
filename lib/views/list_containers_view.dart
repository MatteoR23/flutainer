import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
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
    return _ListContainersScaffoldView(
      currentCredential: currentCredential,
    );
  }
}

class _ListContainersScaffoldView extends StatefulWidget {
  const _ListContainersScaffoldView({required this.currentCredential});

  final EndpointCredential currentCredential;

  @override
  State<_ListContainersScaffoldView> createState() =>
      _ListContainersScaffoldViewState();
}

class _ListContainersScaffoldViewState
    extends State<_ListContainersScaffoldView> {
  bool _controlsExpanded = true;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ListContainersViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.containersAppBarTitle),
        actions: [
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
        currentCredentialId: widget.currentCredential.id,
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
        message: context.l10n
            .environmentLoadError(viewModel.environmentError ?? ''),
        actionLabel: context.l10n.retry,
        onAction: viewModel.loadEnvironments,
      );
    }

    if (viewModel.environments.isEmpty) {
      return _ErrorState(
        message: context.l10n.noEnvironmentsMessage,
        actionLabel: context.l10n.refreshButton,
        onAction: viewModel.loadEnvironments,
      );
    }

    final theme = Theme.of(context);
    final selectedEnv = viewModel.selectedEnvironment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildControlsCard(context, viewModel, selectedEnv?.id),
        const SizedBox(height: 8),
        if (viewModel.containersError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              context.l10n
                  .containersLoadError(viewModel.containersError ?? ''),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        Expanded(
          child: _buildContainersSection(viewModel, theme, context),
        ),
      ],
    );
  }

  Widget _buildControlsCard(
    BuildContext context,
    ListContainersViewModel viewModel,
    int? selectedEnvironmentId,
  ) {
    return Card(
      child: ExpansionTile(
        key: const PageStorageKey('containers_controls_panel'),
        initiallyExpanded: _controlsExpanded,
        onExpansionChanged: (expanded) {
          setState(() => _controlsExpanded = expanded);
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(context.l10n.containersControlsTitle),
        subtitle: Text(context.l10n.containersControlsSubtitle),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: DropdownButtonFormField<int>(
              initialValue: selectedEnvironmentId,
              decoration: InputDecoration(
                labelText: context.l10n.environmentLabel,
                border: const OutlineInputBorder(),
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
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const PageStorageKey('containers_search_field'),
            initialValue: viewModel.searchQuery,
            onChanged: viewModel.setSearchQuery,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: context.l10n.searchHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.icon(
                onPressed: viewModel.isLoadingContainers
                    ? null
                    : viewModel.refreshContainers,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.refreshButton),
              ),
              const SizedBox(width: 12),
              Switch.adaptive(
                value: viewModel.autoRefreshEnabled,
                onChanged: viewModel.setAutoRefresh,
              ),
              const SizedBox(width: 4),
              Text(context.l10n.autoRefreshLabel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContainersSection(
    ListContainersViewModel viewModel,
    ThemeData theme,
    BuildContext context,
  ) {
    if (viewModel.isLoadingContainers) {
      return const Center(child: CircularProgressIndicator());
    }

    final containers = viewModel.filteredContainers;
    if (viewModel.containers.isEmpty) {
      return _ErrorState(
        message: context.l10n.noContainersMessage,
      );
    }

    if (containers.isEmpty) {
      return _ErrorState(
        message: context.l10n.noSearchResultsMessage,
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
          credential: widget.currentCredential,
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
                  tooltip: context.l10n.startAction,
                  onPressed: isBusy
                      ? null
                      : () => viewModel.startContainer(container.id),
                  icon: const Icon(Icons.play_arrow),
                ),
              if (container.canStop)
                IconButton(
                  tooltip: context.l10n.stopAction,
                  onPressed: isBusy
                      ? null
                      : () => viewModel.stopContainer(container.id),
                  icon: const Icon(Icons.stop),
                ),
              if (container.canPause)
                IconButton(
                  tooltip: context.l10n.pauseAction,
                  onPressed: isBusy
                      ? null
                      : () => viewModel.pauseContainer(container.id),
                  icon: const Icon(Icons.pause),
                ),
              if (container.canUnpause)
                IconButton(
                  tooltip: context.l10n.resumeAction,
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
              label: Text(context.l10n.viewLogAction),
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
