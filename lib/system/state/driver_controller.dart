import '../models/trip_model.dart';
import '../models/user_model.dart';
import '../models/route_model.dart';
import '../services/backend_api_service.dart';

class DriverController {
  final BackendApiService _api;

  DriverController({BackendApiService? api})
    : _api = api ?? BackendApiService();

  Future<List<TripModel>> getDriverTrips(String driverId) {
    return _api.getTripsForUser(driverId);
  }

  Future<List<RouteModel>> getSavedRoutes(String driverId) {
    return _api.getSavedRoutes(driverId);
  }

  Future<void> acceptRide({required String tripId}) async {
    await _api.updateTripStatus(tripId: tripId, status: 'accepted');
  }

  Future<void> cancelRide({required String tripId}) async {
    await _api.updateTripStatus(tripId: tripId, status: 'cancelled');
  }

  Future<void> completeTrip({required String tripId}) async {
    await _api.updateTripStatus(tripId: tripId, status: 'completed');
  }

  Future<UserModel?> getDriverProfile(String driverId) async {
    return _api.getDriverProfile(driverId);
  }

  Future<UserModel?> getUserProfile(String userId) async {
    return _api.getUserProfile(userId);
  }

  void updateDocument({required String driverId, required String docType}) {
    // TODO: upload to storage and update row.
    // Placeholder only.
    final unusedDriverID = driverId;
    final unusedDocType = docType;
    (unusedDriverID, unusedDocType);
  }

  Future<RouteModel?> getActiveRouteForTrip({required String tripId}) async {
    // TODO: fetch route for a trip.
    return null;
  }
}
