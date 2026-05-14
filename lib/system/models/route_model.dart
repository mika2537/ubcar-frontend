class RouteModel {
  final String id;
  final String? userId;
  final String from;
  final String to;
  final List<String> midpoints;

  const RouteModel({
    required this.id,
    this.userId,
    required this.from,
    required this.to,
    this.midpoints = const [],
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String?,
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      midpoints: (json['midpoints'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'from': from,
      'to': to,
      'midpoints': midpoints,
    };
  }
}
