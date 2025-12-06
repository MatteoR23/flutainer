import 'package:flutter/material.dart';

import '../services/app_logger.dart';

class ThemeViewModel extends ChangeNotifier {
  ThemeViewModel({
    ThemeMode initialMode = ThemeMode.system,
    AppLogger? logger,
  }) : _logger = logger ?? AppLogger.instance {
    _mode = initialMode;
  }

  final AppLogger _logger;
  late ThemeMode _mode;

  ThemeMode get mode => _mode;

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _logger.log('Theme changed to ${mode.name}');
    notifyListeners();
  }
}
