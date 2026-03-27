class TripModel {
  final String id;
  final String status; // e.g. 'active' | 'completed'
  final DateTime createdAt;

  const TripModel({
    required this.id,
    required this.status,
    required this.createdAt,
  });
}

