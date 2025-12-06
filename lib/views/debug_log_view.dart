import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/l10n.dart';
import '../services/app_logger.dart';

class DebugLogView extends StatelessWidget {
  const DebugLogView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.debugLogTitle),
        actions: [
          Consumer<AppLogger>(
            builder: (context, logger, _) {
              final entries = logger.entries;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.ios_share),
                    tooltip: context.l10n.logExportButton,
                    onPressed: entries.isEmpty
                        ? null
                        : () => _exportLogs(context, entries),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: context.l10n.logClearTooltip,
                    onPressed:
                        entries.isEmpty ? null : () => logger.clear(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<AppLogger>(
        builder: (context, logger, _) {
          final logs = logger.entries;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  context.l10n.appLogsInfo,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: logs.isEmpty
                    ? Center(
                        child: Text(context.l10n.debugLogEmpty),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) => SelectableText(
                          logs[index],
                        ),
                        separatorBuilder: (context, index) => const Divider(),
                        itemCount: logs.length,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportLogs(BuildContext context, List<String> logs) async {
    final l10n = context.l10n;
    try {
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File('${dir.path}/flutainer-log-$timestamp.txt');
      await file.writeAsString(logs.reversed.join('\n'));
      await Share.shareXFiles(
        [XFile(file.path)],
        text: l10n.logExportInstructions,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.logExportSuccess)),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.logExportError(error.toString())),
        ),
      );
    }
  }
}
