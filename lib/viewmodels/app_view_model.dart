import 'package:flutter/foundation.dart';

import '../models/endpoint_credential.dart';
import '../services/credentials_storage.dart';

class AppViewModel extends ChangeNotifier {
  AppViewModel({CredentialsStorage? storage})
      : _storage = storage ?? SecureCredentialsStorage() {
    _hydrate();
  }

  final CredentialsStorage _storage;
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
    } catch (error) {
      _errorMessage = 'Impossibile caricare le credenziali: $error';
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
  }

  Future<void> deleteCredential(String id) async {
    _credentials.removeWhere((cred) => cred.id == id);
    await _persist();
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
    notifyListeners();
  }
}
