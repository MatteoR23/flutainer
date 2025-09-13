import 'package:flutter/material.dart';
import 'package:flutainer/services/portainer_service.dart';

class ContainerListScreen extends StatefulWidget {
  final String url;
  final String apiKey;

  const ContainerListScreen({super.key, required this.url, required this.apiKey});

  @override
  State<ContainerListScreen> createState() => _ContainerListScreenState();
}

class _ContainerListScreenState extends State<ContainerListScreen> {
  late PortainerService service;

  @override
  void initState() {
    super.initState();
    service = PortainerService(widget.url, widget.apiKey);
  }

  Future<void> _refresh() async {
    setState(() {});
  }

  Color _statusColor(String status) {
    switch (status) {
      case "running":
        return Colors.green.shade200;
      case "paused":
        return Colors.orange.shade200;
      default:
        return Colors.red.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("I tuoi container")),
      body: FutureBuilder<List<dynamic>>(
        future: service.getContainers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Errore: ${snapshot.error}"));
          }
          final containers = snapshot.data ?? [];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: containers.length,
              itemBuilder: (context, index) {
                final c = containers[index];
                final id = c['Id'];
                final name = (c['Names'] as List).first.toString().replaceAll("/", "");
                final state = c['State'];
                return Card(
                  color: _statusColor(state),
                  child: ListTile(
                    title: Text(name),
                    subtitle: Text('Stato: $state'),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () async {
                            await service.startOrUnpauseContainer(id);
                            _refresh();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.stop),
                          onPressed: () async {
                            await service.stopContainer(id);
                            _refresh();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.pause),
                          onPressed: () async {
                            await service.pauseContainer(id);
                            _refresh();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
