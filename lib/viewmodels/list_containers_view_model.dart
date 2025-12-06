import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/portainer_container.dart';
import '../models/portainer_environment.dart';
import '../services/portainer_service.dart';

class ListContainersViewModel extends ChangeNotifier {
  ListContainersViewModel({required this.service});

  final PortainerService service;

  List<PortainerEnvironment> _environments = <PortainerEnvironment>[];
  List<PortainerContainer> _containers = <PortainerContainer>[];
  PortainerEnvironment? _selectedEnvironment;
  final Set<String> _busyContainerIds = <String>{};
  bool _autoRefreshEnabled = false;
  Timer? _autoRefreshTimer;
  String _searchQuery = '';

  bool _isLoadingEnvironments = false;
  bool _isLoadingContainers = false;
  String? _environmentError;
  String? _containersError;

  List<PortainerEnvironment> get environments => _environments;
  List<PortainerContainer> get containers => _containers;
  PortainerEnvironment? get selectedEnvironment => _selectedEnvironment;
  bool get isLoadingEnvironments => _isLoadingEnvironments;
  bool get isLoadingContainers => _isLoadingContainers;
  String? get environmentError => _environmentError;
  String? get containersError => _containersError;
  bool get autoRefreshEnabled => _autoRefreshEnabled;
  String get searchQuery => _searchQuery;
  List<PortainerContainer> get filteredContainers {
    if (_searchQuery.trim().isEmpty) {
      return _containers;
    }
    final query = _searchQuery.toLowerCase();
    return _containers
        .where((container) => container.name.toLowerCase().contains(query))
        .toList();
  }

  bool isContainerBusy(String id) => _busyContainerIds.contains(id);

  Future<void> initialize() async {
    await loadEnvironments();
  }

  Future<void> loadEnvironments() async {
    _isLoadingEnvironments = true;
    _environmentError = null;
    notifyListeners();
    try {
      final data = await service.fetchEnvironments();
      _environments = data;
      if (data.isEmpty) {
        _selectedEnvironment = null;
        _containers = <PortainerContainer>[];
        _containersError = null;
      } else {
        final desiredId = _selectedEnvironment?.id;
        if (desiredId != null &&
            data.any((env) => env.id == desiredId)) {
          _selectedEnvironment =
              data.firstWhere((env) => env.id == desiredId);
        } else {
          _selectedEnvironment = data.first;
        }
        await _loadContainersForSelected();
        return;
      }
    } catch (error) {
      _environmentError = error.toString();
    } finally {
      _isLoadingEnvironments = false;
      notifyListeners();
    }
  }

  Future<void> selectEnvironment(int environmentId) async {
    try {
      final environment = _environments
          .firstWhere((env) => env.id == environmentId);
      if (_selectedEnvironment?.id == environment.id) return;
      _selectedEnvironment = environment;
      notifyListeners();
      await _loadContainersForSelected();
    } catch (_) {
      // ignore when environment is missing
    }
  }

  Future<void> refreshContainers({bool showLoading = true}) async {
    await _loadContainersForSelected(showLoading: showLoading);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setAutoRefresh(bool enabled) {
    if (_autoRefreshEnabled == enabled) return;
    _autoRefreshEnabled = enabled;
    if (enabled) {
      _startAutoRefresh();
      unawaited(_loadContainersForSelected(showLoading: false));
    } else {
      _stopAutoRefresh();
    }
    notifyListeners();
  }

  Future<void> startContainer(String containerId) async {
    await _runContainerAction(
      containerId,
      (envId, id) => service.startContainer(envId, id),
    );
  }

  Future<void> stopContainer(String containerId) async {
    await _runContainerAction(
      containerId,
      (envId, id) => service.stopContainer(envId, id),
    );
  }

  Future<void> pauseContainer(String containerId) async {
    await _runContainerAction(
      containerId,
      (envId, id) => service.pauseContainer(envId, id),
    );
  }

  Future<void> unpauseContainer(String containerId) async {
    await _runContainerAction(
      containerId,
      (envId, id) => service.unpauseContainer(envId, id),
    );
  }

  Future<void> _loadContainersForSelected({bool showLoading = true}) async {
    final environment = _selectedEnvironment;
    if (environment == null) {
      _containers = <PortainerContainer>[];
      _containersError = null;
      _stopAutoRefresh();
      notifyListeners();
      return;
    }
    if (showLoading) {
      _isLoadingContainers = true;
      _containersError = null;
      notifyListeners();
    }
    try {
      final data = await service.fetchContainers(environment.id);
      data.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      _containers = data;
      _containersError = null;
    } catch (error) {
      if (showLoading) {
        _containers = <PortainerContainer>[];
      }
      _containersError = error.toString();
    } finally {
      if (showLoading) {
        _isLoadingContainers = false;
      }
      notifyListeners();
    }
  }

  Future<void> _runContainerAction(
    String containerId,
    Future<void> Function(int environmentId, String containerId) action,
  ) async {
    final environment = _selectedEnvironment;
    if (environment == null) return;
    _busyContainerIds.add(containerId);
    notifyListeners();
    try {
      await action(environment.id, containerId);
      await _loadContainersForSelected(showLoading: false);
    } catch (error) {
      _containersError = error.toString();
      notifyListeners();
    } finally {
      _busyContainerIds.remove(containerId);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    service.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (!_autoRefreshEnabled) return;
        unawaited(_loadContainersForSelected(showLoading: false));
      },
    );
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }
}
