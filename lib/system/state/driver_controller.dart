import '../models/trip_model.dart';
import '../models/user_model.dart';
import '../models/route_model.dart';
import '../services/supabase_service.dart';

class DriverController {
  final SupabaseService _supabase;

  DriverController({SupabaseService? supabase})
      : _supabase = supabase ?? const SupabaseService();

  Future<List<TripModel>> getDriverTrips(String driverId) {
    return _supabase.getTripsForUser(driverId);
  }

  Future<void> acceptRide({
    required String tripId,
  }) async {
    // Convention example: 'accepted'
    await _supabase.updateTripStatus(tripId: tripId, status: 'accepted');
  }

  Future<void> completeTrip({
    required String tripId,
  }) async {
    await _supabase.updateTripStatus(tripId: tripId, status: 'completed');
  }

  Future<UserModel?> getDriverProfile(String driverId) async {
    // TODO: add dedicated profile fetch.
    final user = await _supabase.getCurrentUser();
    return (user?.id == driverId) ? user : user;
  }

  void updateDocument({
    required String driverId,
    required String docType,
  }) {
    // TODO: upload to storage and update row.
    // Placeholder only.
    (void,)driverId;
    (void,)docType;
  }

  Future<RouteModel?> getActiveRouteForTrip({
    required String tripId,
  }) async {
    // TODO: fetch route for a trip.
    return null;
  }
}

