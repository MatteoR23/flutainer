class EndpointCredential {
  EndpointCredential({
    required this.id,
    required this.name,
    required this.url,
    required this.apiKey,

  });

  factory EndpointCredential.create({
    required String url,
    required String apiKey,
    required String name,
  }) {
    return EndpointCredential(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      url: url.trim(),
      name: name.trim(),
      apiKey: apiKey.trim(),
    );
  }

  factory EndpointCredential.fromMap(Map<String, dynamic> map) {
    return EndpointCredential(
      id:
          map['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: map['name'] as String? ?? '',
      url: map['url'] as String? ?? '',
      apiKey: map['apiKey'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final String url;
  final String apiKey;

  EndpointCredential copyWith({String? url, String? apiKey, String? name}) {
    return EndpointCredential(
      id: id,
      name: name?.trim() ?? this.name,
      url: url?.trim() ?? this.url,
      apiKey: apiKey?.trim() ?? this.apiKey,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'url': url,
      'name': name,
      'apiKey': apiKey,
    };
  }
}
