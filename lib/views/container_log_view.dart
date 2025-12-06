import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/endpoint_credential.dart';
import '../models/portainer_container.dart';
import '../services/portainer_service.dart';
import '../viewmodels/container_log_view_model.dart';

class ContainerLogView extends StatelessWidget {
  const ContainerLogView({
    super.key,
    required this.credential,
    required this.environmentId,
    required this.container,
  });

  final EndpointCredential credential;
  final int environmentId;
  final PortainerContainer container;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ContainerLogViewModel>(
      create: (_) => ContainerLogViewModel(
        service: PortainerService(credential: credential),
        environmentId: environmentId,
        containerId: container.id,
      )..initialize(),
      child: _ContainerLogScaffold(containerName: container.name),
    );
  }
}

class _ContainerLogScaffold extends StatefulWidget {
  const _ContainerLogScaffold({required this.containerName});

  final String containerName;

  @override
  State<_ContainerLogScaffold> createState() => _ContainerLogScaffoldState();
}

class _ContainerLogScaffoldState extends State<_ContainerLogScaffold> {
  final TextEditingController _linesController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _linesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContainerLogViewModel>(
      builder: (context, viewModel, _) {
        _syncControllers(viewModel);
        return Scaffold(
          appBar: AppBar(
            title: Text('${widget.containerName} - View Log'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPreferencesPanel(context, viewModel),
                const SizedBox(height: 16),
                Expanded(child: _buildLogArea(context, viewModel)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _syncControllers(ContainerLogViewModel viewModel) {
    final lines = viewModel.lineCount.toString();
    if (_linesController.text != lines) {
      _linesController.text = lines;
      _linesController.selection = TextSelection.fromPosition(
        TextPosition(offset: _linesController.text.length),
      );
    }
  }

  Widget _buildPreferencesPanel(
    BuildContext context,
    ContainerLogViewModel viewModel,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final content = _buildPreferencesContent(
          context,
          viewModel,
          isWide: isWide,
        );

        if (isWide) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: content,
            ),
          );
        }

        return Card(
          child: ExpansionTile(
            initiallyExpanded: false,
            maintainState: true,
            title: const Text('Log preferences'),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            children: [content],
          ),
        );
      },
    );
  }

  Widget _buildPreferencesContent(
    BuildContext context,
    ContainerLogViewModel viewModel, {
    required bool isWide,
  }) {
    final leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLinesControls(viewModel),
        const SizedBox(height: 12),
        _buildToggleRow(viewModel),
      ],
    );

    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftColumn,
          const Divider(height: 32),
          _buildDisplayOptions(viewModel),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: leftColumn,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: _buildDisplayOptions(viewModel),
          ),
        ),
      ],
    );
  }

  Widget _buildLinesControls(ContainerLogViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lines & Refresh',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _linesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Lines (default 1000)',
                ),
                onSubmitted: (_) => _applyLineCount(viewModel),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => _applyLineCount(viewModel),
              child: const Text('Apply'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleRow(ContainerLogViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _preferenceSwitchTile(
                title: 'Auto-refresh',
                subtitle: 'Aggiorna log automaticamente',
                value: viewModel.autoRefresh,
                onChanged: viewModel.toggleAutoRefresh,
              ),
            ),
            if (!viewModel.autoRefresh)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: FilledButton.icon(
                  onPressed: viewModel.isLoading ? null : viewModel.refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _preferenceSwitchTile(
          title: 'Wrap log lines',
          subtitle: 'Disattiva per scorrere orizzontalmente',
          value: viewModel.wrapLines,
          onChanged: viewModel.setWrapLines,
        ),
      ],
    );
  }

  void _applyLineCount(ContainerLogViewModel viewModel) {
    final parsed = int.tryParse(_linesController.text.trim());
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un numero di righe valido')),
      );
      return;
    }
    viewModel.setLineCount(parsed);
  }

  Widget _buildDisplayOptions(ContainerLogViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Display',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SegmentedButton<LogLabelMode>(
          segments: const [
            ButtonSegment<LogLabelMode>(
              value: LogLabelMode.lineNumber,
              label: Text('Line Number'),
              icon: Icon(Icons.format_list_numbered),
            ),
            ButtonSegment<LogLabelMode>(
              value: LogLabelMode.timestamp,
              label: Text('Timestamp'),
              icon: Icon(Icons.access_time),
            ),
          ],
          selected: <LogLabelMode>{viewModel.labelMode},
          onSelectionChanged: (selection) =>
              viewModel.setLabelMode(selection.first),
        ),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text('Wrap log lines'),
          subtitle: const Text('Disattiva per scorrere orizzontalmente'),
          value: viewModel.wrapLines,
          onChanged: viewModel.setWrapLines,
        ),
      ],
    );
  }

  Widget _buildLogArea(
    BuildContext context,
    ContainerLogViewModel viewModel,
  ) {
    if (viewModel.isLoading && viewModel.entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.errorMessage != null && viewModel.entries.isEmpty) {
      return _ErrorState(
        message: viewModel.errorMessage!,
        onRetry: viewModel.refresh,
      );
    }
    if (viewModel.entries.isEmpty) {
      return const _EmptyState();
    }

    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        );
    final logStyle = const TextStyle(
      fontFamily: 'monospace',
      fontSize: 13,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SelectionArea(
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: ListView.builder(
            controller: _scrollController,
            itemCount: viewModel.entries.length,
            itemBuilder: (context, index) {
              final entry = viewModel.entries[index];
              final label = viewModel.labelMode == LogLabelMode.lineNumber
                  ? '${index + 1}'.padLeft(4, '0')
                  : entry.formattedTimestamp;
              final messageWidget = Text(
                entry.message,
                style: logStyle,
                softWrap: viewModel.wrapLines,
              );
              Widget messageDisplay;
              if (viewModel.wrapLines) {
                messageDisplay = messageWidget;
              } else {
                messageDisplay = SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 0),
                    child: messageWidget,
                  ),
                );
              }
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(label, style: labelStyle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: messageDisplay),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Riprova'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Nessun log disponibile per questo container.',
        textAlign: TextAlign.center,
      ),
    );
  }
}

  Widget _preferenceSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
