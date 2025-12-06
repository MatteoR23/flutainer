class ContainerLogEntry {
  const ContainerLogEntry({
    required this.message,
    this.timestamp,
  });

  final DateTime? timestamp;
  final String message;

  String get formattedTimestamp =>
      timestamp?.toLocal().toIso8601String() ?? '';
}
