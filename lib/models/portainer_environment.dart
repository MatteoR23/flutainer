class PortainerEnvironment {
  const PortainerEnvironment({
    required this.id,
    required this.name,
  });

  factory PortainerEnvironment.fromJson(Map<String, dynamic> json) {
    return PortainerEnvironment(
      id: json['Id'] is int
          ? json['Id'] as int
          : int.tryParse('${json['Id']}') ?? 0,
      name: json['Name'] as String? ?? 'Environment',
    );
  }

  final int id;
  final String name;
}
