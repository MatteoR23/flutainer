import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/container_log_entry.dart';
import '../services/portainer_service.dart';

enum LogLabelMode { lineNumber, timestamp }

class ContainerLogViewModel extends ChangeNotifier {
  ContainerLogViewModel({
    required this.service,
    required this.environmentId,
    required this.containerId,
  });

  final PortainerService service;
  final int environmentId;
  final String containerId;

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
    } catch (error) {
      _errorMessage = error.toString();
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
    notifyListeners();
    unawaited(loadLogs());
  }

  void toggleAutoRefresh(bool value) {
    if (_autoRefresh == value) return;
    _autoRefresh = value;
    if (value) {
      _startTimer();
    } else {
      _refreshTimer?.cancel();
      _refreshTimer = null;
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
