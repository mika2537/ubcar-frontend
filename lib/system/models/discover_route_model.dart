import 'route_model.dart';
import 'user_model.dart';

class DiscoverRouteModel {
  final RouteModel route;
  final UserModel driver;
  final int activeTripCount;
  final int completedTripCount;

  const DiscoverRouteModel({
    required this.route,
    required this.driver,
    required this.activeTripCount,
    required this.completedTripCount,
  });

  factory DiscoverRouteModel.fromJson(Map<String, dynamic> json) {
    return DiscoverRouteModel(
      route: RouteModel.fromJson(
        json['route'] as Map<String, dynamic>? ?? const {},
      ),
      driver: UserModel.fromJson(
        json['driver'] as Map<String, dynamic>? ?? const {},
      ),
      activeTripCount: (json['activeTripCount'] as num?)?.toInt() ?? 0,
      completedTripCount: (json['completedTripCount'] as num?)?.toInt() ?? 0,
    );
  }
}
