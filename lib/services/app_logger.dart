import 'package:flutter/foundation.dart';

class AppLogger extends ChangeNotifier {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  final List<String> _entries = <String>[];
  int _counter = 0;

  List<String> get entries => List<String>.unmodifiable(_entries.reversed);

  void log(String message) {
    final stamp = DateTime.now().toIso8601String();
    final entry = '#${++_counter} [$stamp] $message';
    _entries.add(entry);
    if (_entries.length > 500) {
      _entries.removeRange(0, _entries.length - 500);
    }
    if (kDebugMode) {
      // Still forward logs to console when debugging.
      debugPrint(entry);
    }
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }
}
