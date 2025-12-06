import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_logger.dart';

class DebugLogView extends StatelessWidget {
  const DebugLogView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log applicazione'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Svuota log',
            onPressed: () => context.read<AppLogger>().clear(),
          ),
        ],
      ),
      body: Consumer<AppLogger>(
        builder: (context, logger, _) {
          final logs = logger.entries;
          if (logs.isEmpty) {
            return const Center(
              child: Text('Nessun log disponibile'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) => SelectableText(logs[index]),
            separatorBuilder: (context, index) => const Divider(),
            itemCount: logs.length,
          );
        },
      ),
    );
  }
}
