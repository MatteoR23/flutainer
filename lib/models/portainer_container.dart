enum ContainerVisualState { running, paused, stopped, error }

class PortainerContainer {
  PortainerContainer({
    required this.id,
    required this.name,
    required this.state,
    required this.statusText,
    required this.exitCode,
  });

  factory PortainerContainer.fromJson(Map<String, dynamic> json) {
    final names = (json['Names'] as List<dynamic>?)
            ?.map((value) => value.toString())
            .toList() ??
        <String>[];
    final normalizedName = names.isNotEmpty
        ? names.first.replaceFirst(RegExp(r'^/+'), '')
        : (json['Names']?.toString() ?? '');
    final statusText = json['Status'] as String? ?? '';
    return PortainerContainer(
      id: json['Id'] as String? ?? '',
      name: normalizedName.isEmpty
          ? (json['Image'] as String? ?? 'Container')
          : normalizedName,
      state: (json['State'] as String? ?? '').toLowerCase(),
      statusText: statusText,
      exitCode: _extractExitCode(statusText),
    );
  }

  final String id;
  final String name;
  final String state;
  final String statusText;
  final int? exitCode;

  static int? _extractExitCode(String statusText) {
    final match = RegExp(r'\((\-?\d+)\)').firstMatch(statusText);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  bool get isRunning => state == 'running';
  bool get isPaused => state == 'paused';
  bool get isStopped =>
      state == 'exited' ||
      state == 'dead' ||
      state == 'created' ||
      state == 'removing';

  bool get hasBadExit => isStopped && (exitCode ?? 0) != 0;

  bool get canStart => !isRunning;
  bool get canStop => isRunning || isPaused;
  bool get canPause => isRunning;
  bool get canUnpause => isPaused;

  ContainerVisualState get visualState {
    if (isRunning) return ContainerVisualState.running;
    if (isPaused) return ContainerVisualState.paused;
    if (hasBadExit) return ContainerVisualState.error;
    return ContainerVisualState.stopped;
  }
}
