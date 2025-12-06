import 'package:flutter/foundation.dart';

import '../models/endpoint_credential.dart';
import '../services/app_logger.dart';
import '../services/credentials_storage.dart';

class AppViewModel extends ChangeNotifier {
  AppViewModel({CredentialsStorage? storage, AppLogger? logger})
      : _storage = storage ?? SecureCredentialsStorage(),
        _logger = logger ?? AppLogger.instance {
    _hydrate();
  }

  final CredentialsStorage _storage;
  final AppLogger _logger;
  final List<EndpointCredential> _credentials = [];

  bool _isLoading = true;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<EndpointCredential> get credentials =>
      List<EndpointCredential>.unmodifiable(_credentials);

  Future<void> _hydrate() async {
    try {
      final stored = await _storage.readAll();
      _credentials
        ..clear()
        ..addAll(stored);
      _errorMessage = null;
      _logger.log('Loaded ${_credentials.length} credential(s) from storage');
    } catch (error) {
      _errorMessage = error.toString();
      _logger.logError('Failed to load credentials: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    await _hydrate();
  }

  Future<EndpointCredential> addCredential({
    required String url,
    required String apiKey,
    required String name,
  }) async {
    final credential = EndpointCredential.create(url: url, apiKey: apiKey, name: name);
    _credentials.add(credential);
    await _persist();
    _logger.log('Added credential "${credential.name.isEmpty ? credential.url : credential.name}"');
    return credential;
  }

  Future<void> updateCredential(
    String id, {
    String? url,
    String? apiKey,
    String? name,
  }) async {
    final index = _credentials.indexWhere((cred) => cred.id == id);
    if (index == -1) {
      throw StateError('Credential $id not found');
    }
    final updated = _credentials[index].copyWith(
      url: url,
      apiKey: apiKey,
      name: name,
    );
    _credentials[index] = updated;
    await _persist();
    _logger.log('Updated credential "${updated.name.isEmpty ? updated.url : updated.name}"');
  }

  Future<void> deleteCredential(String id) async {
    final removed = _credentials.where((cred) => cred.id == id).toList();
    _credentials.removeWhere((cred) => cred.id == id);
    await _persist();
    if (removed.isNotEmpty) {
      final cred = removed.first;
      _logger.log('Deleted credential "${cred.name.isEmpty ? cred.url : cred.name}"');
    }
  }

  EndpointCredential? credentialById(String id) {
    try {
      return _credentials.firstWhere((cred) => cred.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persist() async {
    await _storage.writeAll(_credentials);
    notifyListeners();
  }

  Future<void> clearAll() async {
    _credentials.clear();
    await _storage.clear();
    _logger.log('Cleared all stored credentials');
    notifyListeners();
  }
}
