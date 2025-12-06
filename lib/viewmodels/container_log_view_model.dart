import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/container_log_entry.dart';
import '../services/app_logger.dart';
import '../services/portainer_service.dart';

enum LogLabelMode { lineNumber, timestamp }

class ContainerLogViewModel extends ChangeNotifier {
  ContainerLogViewModel({
    required this.service,
    required this.environmentId,
    required this.containerId,
  }) : _logger = AppLogger.instance;

  final PortainerService service;
  final int environmentId;
  final String containerId;
  final AppLogger _logger;

  static const String _linesKey = 'container_log_lines';

  List<ContainerLogEntry> _entries = <ContainerLogEntry>[];
  bool _isLoading = false;
  String? _errorMessage;
  int _lineCount = 1000;
  bool _autoRefresh = false;
  bool _wrapLines = true;
  LogLabelMode _labelMode = LogLabelMode.timestamp;
  Timer? _refreshTimer;
  SharedPreferences? _prefs;

  List<ContainerLogEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get lineCount => _lineCount;
  bool get autoRefresh => _autoRefresh;
  bool get wrapLines => _wrapLines;
  LogLabelMode get labelMode => _labelMode;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _lineCount = _prefs?.getInt(_linesKey) ?? 1000;
    await loadLogs();
  }

  Future<void> loadLogs({bool showLoading = true}) async {
    if (_isLoading) return;
    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }
    try {
      final logs = await service.fetchContainerLogs(
        environmentId: environmentId,
        containerId: containerId,
        tail: _lineCount,
      );
      _entries = logs;
      _errorMessage = null;
      _logger.log('Loaded ${logs.length} log line(s) for container $containerId');
    } catch (error) {
      _errorMessage = error.toString();
      _logger.logError('Failed to load container logs: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadLogs();

  void setLineCount(int value) {
    final sanitized = value <= 0 ? 1000 : value;
    if (_lineCount == sanitized) return;
    _lineCount = sanitized;
    _prefs?.setInt(_linesKey, _lineCount);
    _logger.log('Updated log line count to $_lineCount');
    notifyListeners();
    unawaited(loadLogs());
  }

  void toggleAutoRefresh(bool value) {
    if (_autoRefresh == value) return;
    _autoRefresh = value;
    if (value) {
      _startTimer();
      _logger.log('Enabled auto refresh for container logs');
    } else {
      _refreshTimer?.cancel();
      _refreshTimer = null;
      _logger.log('Disabled auto refresh for container logs');
    }
    notifyListeners();
  }

  void _startTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => loadLogs(showLoading: false),
    );
  }

  void setLabelMode(LogLabelMode mode) {
    if (_labelMode == mode) return;
    _labelMode = mode;
    notifyListeners();
  }

  void setWrapLines(bool value) {
    if (_wrapLines == value) return;
    _wrapLines = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    service.dispose();
    super.dispose();
  }
}
