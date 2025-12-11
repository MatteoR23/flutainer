import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/endpoint_credential.dart';

abstract class CredentialsStorage {
  Future<List<EndpointCredential>> readAll();
  Future<void> writeAll(List<EndpointCredential> credentials);
  Future<void> clear();
}

class SecureCredentialsStorage implements CredentialsStorage {
  SecureCredentialsStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions:
                  IOSOptions(accessibility: KeychainAccessibility.first_unlock),
              mOptions: MacOsOptions(
                  accessibility: KeychainAccessibility.first_unlock),
              lOptions: LinuxOptions(),
              webOptions: WebOptions.defaultOptions,
            );

  static const _key = 'flutainer.endpoint.credentials';
  final FlutterSecureStorage _storage;

  @override
  Future<void> clear() {
    return _storage.delete(key: _key);
  }

  @override
  Future<List<EndpointCredential>> readAll() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) {
      return <EndpointCredential>[];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) =>
            EndpointCredential.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<void> writeAll(List<EndpointCredential> credentials) {
    final payload =
        jsonEncode(credentials.map((cred) => cred.toMap()).toList());
    return _storage.write(key: _key, value: payload);
  }
}

class MemoryCredentialsStorage implements CredentialsStorage {
  final List<EndpointCredential> _buffer = [];

  @override
  Future<void> clear() async {
    _buffer.clear();
  }

  @override
  Future<List<EndpointCredential>> readAll() async {
    return List<EndpointCredential>.from(_buffer);
  }

  @override
  Future<void> writeAll(List<EndpointCredential> credentials) async {
    _buffer
      ..clear()
      ..addAll(credentials);
  }
}
