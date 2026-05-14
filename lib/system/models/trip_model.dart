import 'route_model.dart';

class TripModel {
  final String id;
  final String? passengerId;
  final String? passengerName;
  final double passengerRating;
  final String? driverId;
  final RouteModel? route;
  final String status; // e.g. 'active' | 'completed'
  final int seatsRequested;
  final DateTime createdAt;

  const TripModel({
    required this.id,
    this.passengerId,
    this.passengerName,
    this.passengerRating = 4.8,
    this.driverId,
    this.route,
    required this.status,
    this.seatsRequested = 1,
    required this.createdAt,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'] as String? ?? '',
      passengerId: json['passengerId'] as String?,
      passengerName: json['passengerName'] as String?,
      passengerRating: (json['passengerRating'] as num?)?.toDouble() ?? 4.8,
      driverId: json['driverId'] as String?,
      route: json['route'] is Map<String, dynamic>
          ? RouteModel.fromJson(json['route'] as Map<String, dynamic>)
          : null,
      status: json['status'] as String? ?? '',
      seatsRequested: (json['seatsRequested'] as num?)?.toInt() ?? 1,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  TripModel copyWith({
    String? id,
    String? passengerId,
    String? passengerName,
    double? passengerRating,
    String? driverId,
    RouteModel? route,
    String? status,
    int? seatsRequested,
    DateTime? createdAt,
  }) {
    return TripModel(
      id: id ?? this.id,
      passengerId: passengerId ?? this.passengerId,
      passengerName: passengerName ?? this.passengerName,
      passengerRating: passengerRating ?? this.passengerRating,
      driverId: driverId ?? this.driverId,
      route: route ?? this.route,
      status: status ?? this.status,
      seatsRequested: seatsRequested ?? this.seatsRequested,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
