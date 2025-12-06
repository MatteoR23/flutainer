import 'package:flutter/foundation.dart';

class AppLogger extends ChangeNotifier {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  final List<String> _entries = <String>[];
  int _counter = 0;

  List<String> get entries => List<String>.unmodifiable(_entries.reversed);

  void log(String message) => _addEntry('INFO', message);

  void logError(String message) => _addEntry('ERROR', message);

  void _addEntry(String level, String message) {
    if (!kDebugMode) return;
    final stamp = DateTime.now().toIso8601String();
    final entry = '#${++_counter} [$stamp][$level] $message';
    _entries.add(entry);
    if (_entries.length > 500) {
      _entries.removeRange(0, _entries.length - 500);
    }
    debugPrint(entry);
    notifyListeners();
  }

  void clear() {
    if (_entries.isEmpty) return;
    _entries.clear();
    notifyListeners();
  }
}
