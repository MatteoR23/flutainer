import 'package:flutter/material.dart';
import 'package:flutainer/services/portainer_service.dart';
import 'package:secure_store/secure_store.dart';
import 'package:flutainer/screens/setup_screen.dart';
import 'package:flutainer/widgets/common_app_bar.dart';

class ContainerListScreen extends StatefulWidget {
  final String url;
  final String apiKey;

  const ContainerListScreen({super.key, required this.url, required this.apiKey});

  @override
  State<ContainerListScreen> createState() => _ContainerListScreenState();
}

class _ContainerListScreenState extends State<ContainerListScreen> {
  late PortainerService service;
  final TextEditingController _searchController = TextEditingController();
  Future<List<dynamic>>? _containersFuture;

  @override
  void initState() {
    super.initState();
    service = PortainerService(widget.url, widget.apiKey);
    _searchController.addListener(() => setState(() {}));
    _loadContainers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadContainers() {
    setState(() {
      _containersFuture = service.getContainers();
    });
  }

  Future<void> _refresh() async {
    // forza il refresh dalla rete
    setState(() {
      _containersFuture = service.getContainers();
    });
    await (_containersFuture ?? Future.value());
  }

  Color _statusColor(String? status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (status) {
      case "running":
        return isDark ? Colors.green.shade700 : Colors.green.shade200;
      case "paused":
        return isDark ? Colors.orange.shade700 : Colors.orange.shade200;
      default:
        return isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    }
  }

  String _extractName(dynamic c) {
    try {
      final names = c['Names'] as List<dynamic>?;
      if (names != null && names.isNotEmpty) {
        return names.first.toString().replaceAll('/', '');
      }
      return c['Name']?.toString() ?? c['Id']?.toString() ?? '';
    } catch (_) {
      return c['Id']?.toString() ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CommonAppBar(
        title: const Text("I tuoi container"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cerca container per nome...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _containersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Errore: ${snapshot.error}"));
                }
                final containers = snapshot.data ?? [];
                final filtered = query.isEmpty
                    ? containers
                    : containers.where((c) {
                        final name = _extractName(c).toLowerCase();
                        return name.contains(query) ||
                            (c['Id']?.toString().toLowerCase().contains(query) ?? false);
                      }).toList();

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final c = filtered[index];
                      final id = c['Id']?.toString() ?? '';
                      final name = _extractName(c);
                      final state = c['State']?.toString() ?? '';

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
                                  try {
                                    await service.startOrUnpauseContainer(id);
                                  } catch (e) {
                                    // ignore: avoid_print
                                    print('Start error: $e');
                                  }
                                  await _refresh();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.stop),
                                onPressed: () async {
                                  try {
                                    await service.stopContainer(id);
                                  } catch (e) {
                                    // ignore: avoid_print
                                    print('Stop error: $e');
                                  }
                                  await _refresh();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.pause),
                                onPressed: () async {
                                  try {
                                    await service.pauseContainer(id);
                                  } catch (e) {
                                    // ignore: avoid_print
                                    print('Pause error: $e');
                                  }
                                  await _refresh();
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
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    // cancella le credenziali dallo storage
    final store = PasswordStore(password: '1234');
    try {
      await store.deleteSecret(key: 'password-store:apiKey');
    } catch (_) {}

    if (!mounted) return;

    // Rimuove tutte le route e mostra la schermata di setup (login)
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SetupScreen()),
      (route) => false,
    );
  }
}
