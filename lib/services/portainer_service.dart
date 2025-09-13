import 'dart:convert';
import 'package:http/http.dart' as http;

class PortainerService {
  final String url;
  final String apiKey;

  PortainerService(this.url, this.apiKey);

  Map<String, String> get headers => {
        'X-API-Key': apiKey,
        'Content-Type': 'application/json',
      };

  Future<List<dynamic>> getEnvironments() async {
    final response = await http.get(Uri.parse('$url/api/endpoints'), headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Errore nel caricamento ambienti: ${response.body}');
    }
  }

  Future<int> _resolveEnvId(int envId) async {
    if (envId != -1) return envId;
    final envs = await getEnvironments();
    if (envs.isEmpty) {
      throw Exception('Nessun ambiente trovato');
    }
    return envs[0]['Id'] as int;
  }

  Future<List<dynamic>> getContainers({int envId = -1}) async {
    envId = await _resolveEnvId(envId);

    final response = await http.get(
        Uri.parse('$url/api/endpoints/$envId/docker/containers/json?all=true'),
        headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Errore nel caricamento container: ${response.body}');
    }
  }

  //Start a container, if it's paused, unpause it
  Future<void> startOrUnpauseContainer(String id, {int envId = -1}) async {
    envId = await _resolveEnvId(envId);

    final response = await http
        .post(Uri.parse('$url/api/endpoints/$envId/docker/containers/$id/start'), headers: headers);
    if (response.statusCode == 409) {
      //Container is paused, unpause it
      await unpauseContainer(id, envId: envId);
    } else if (response.statusCode != 204) {
      throw Exception('Errore start: ${response.body}');
    }
  }

  Future<void> unpauseContainer(String id, {int envId = -1}) async {
    envId = await _resolveEnvId(envId);

    final response = await http.post(
        Uri.parse('$url/api/endpoints/$envId/docker/containers/$id/unpause'),
        headers: headers);
    if (response.statusCode != 204) {
      throw Exception('Errore unpause: ${response.body}');
    }
  }

  Future<void> stopContainer(String id, {int envId = -1}) async {
    envId = await _resolveEnvId(envId);

    final response = await http
        .post(Uri.parse('$url/api/endpoints/$envId/docker/containers/$id/stop'), headers: headers);
    if (response.statusCode != 204) {
      throw Exception('Errore stop: ${response.body}');
    }
  }

  Future<void> pauseContainer(String id, {int envId = -1}) async {
    envId = await _resolveEnvId(envId);

    final response = await http
        .post(Uri.parse('$url/api/endpoints/$envId/docker/containers/$id/pause'), headers: headers);
    if (response.statusCode != 204) {
      throw Exception('Errore pausa: ${response.body}');
    }
  }
}
