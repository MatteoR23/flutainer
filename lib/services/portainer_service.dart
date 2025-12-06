import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/endpoint_credential.dart';
import '../models/portainer_container.dart';
import '../models/portainer_environment.dart';

class PortainerException implements Exception {
  PortainerException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PortainerService {
  PortainerService({
    required this.credential,
    http.Client? client,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null;

  final EndpointCredential credential;
  final http.Client _client;
  final bool _ownsClient;

  Map<String, String> get _headers => <String, String>{
        'X-API-Key': credential.apiKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Uri _buildUri(
    List<String> pathSegments, [
    Map<String, dynamic>? queryParameters,
  ]) {
    final base = Uri.parse(credential.url);
    final baseSegments =
        base.pathSegments.where((segment) => segment.isNotEmpty).toList();
    final hasApiSegment =
        baseSegments.isNotEmpty && baseSegments.first == 'api';
    final segments = <String>[
      if (!hasApiSegment) 'api',
      ...baseSegments,
      ...pathSegments.where((segment) => segment.isNotEmpty),
    ];

    final query = queryParameters?.map((key, value) => MapEntry(
          key,
          value?.toString() ?? '',
        ));

    return base.replace(
      pathSegments: segments,
      queryParameters: query,
    );
  }

  Future<List<PortainerEnvironment>> fetchEnvironments() async {
    final uri = _buildUri(const ['endpoints']);
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw PortainerException(
        'Errore ${response.statusCode} durante il caricamento degli environment',
      );
    }
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) =>
            PortainerEnvironment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<PortainerContainer>> fetchContainers(int environmentId) async {
    final uri = _buildUri(
      ['endpoints', '$environmentId', 'docker', 'containers', 'json'],
      <String, dynamic>{'all': 1},
    );
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw PortainerException(
        'Errore ${response.statusCode} durante il caricamento dei container',
      );
    }
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) =>
            PortainerContainer.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> startContainer(int environmentId, String containerId) {
    return _execContainerAction(
      environmentId,
      containerId,
      'start',
    );
  }

  Future<void> stopContainer(int environmentId, String containerId) {
    return _execContainerAction(
      environmentId,
      containerId,
      'stop',
    );
  }

  Future<void> pauseContainer(int environmentId, String containerId) {
    return _execContainerAction(
      environmentId,
      containerId,
      'pause',
    );
  }

  Future<void> unpauseContainer(int environmentId, String containerId) {
    return _execContainerAction(
      environmentId,
      containerId,
      'unpause',
    );
  }

  Future<void> _execContainerAction(
    int environmentId,
    String containerId,
    String action,
  ) async {
    final uri = _buildUri([
      'endpoints',
      '$environmentId',
      'docker',
      'containers',
      containerId,
      action,
    ]);
    final response = await _client.post(uri, headers: _headers);
    if (response.statusCode >= 400) {
      throw PortainerException(
        'Errore ${response.statusCode} durante l\'azione "$action"',
      );
    }
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
