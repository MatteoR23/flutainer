import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/container_log_entry.dart';
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

  Future<List<ContainerLogEntry>> fetchContainerLogs({
    required int environmentId,
    required String containerId,
    int tail = 1000,
    bool timestamps = true,
    int? sinceSeconds,
  }) async {
    final uri = _buildUri(
      [
        'endpoints',
        '$environmentId',
        'docker',
        'containers',
        containerId,
        'logs',
      ],
      <String, dynamic>{
        'stdout': 1,
        'stderr': 1,
        'tail': tail,
        'timestamps': timestamps ? 1 : 0,
        'follow': 0,
        if (sinceSeconds != null && sinceSeconds > 0) 'since': sinceSeconds,
      },
    );
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw PortainerException(
        'Errore ${response.statusCode} durante il caricamento dei log',
      );
    }
    final payload = response.body;
    if (payload.isEmpty) return <ContainerLogEntry>[];
    final rawLines = payload.split('\n');
    if (rawLines.isNotEmpty && rawLines.last.trim().isEmpty) {
      rawLines.removeLast();
    }
    return rawLines.map(_parseLogLine).toList();
  }

  ContainerLogEntry _parseLogLine(String line) {
    final separatorIndex = line.indexOf(' ');
    if (separatorIndex > 0) {
      final tsString = line.substring(0, separatorIndex);
      final message = line.substring(separatorIndex + 1);
      final timestamp = _parseDockerTimestamp(tsString);
      return ContainerLogEntry(
        timestamp: timestamp,
        message: message,
      );
    }
    return ContainerLogEntry(timestamp: null, message: line);
  }

  DateTime? _parseDockerTimestamp(String value) {
    DateTime? parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
    final regex = RegExp(
      r'^(?<main>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})(\.(?<fraction>\d+))?(?<zone>Z|[+-]\d{2}:\d{2})?$',
    );
    final match = regex.firstMatch(value);
    if (match == null) return null;
    final main = match.namedGroup('main');
    var fraction = match.namedGroup('fraction') ?? '';
    final zone = match.namedGroup('zone') ?? '';
    if (fraction.isEmpty) return null;
    if (fraction.length > 6) {
      fraction = fraction.substring(0, 6);
    } else {
      fraction = fraction.padRight(6, '0');
    }
    final normalized = '$main.$fraction$zone';
    return DateTime.tryParse(normalized);
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
