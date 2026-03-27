import '../models/trip_model.dart';
import '../services/maps_service.dart';
import '../services/supabase_service.dart';

class TripController {
  final SupabaseService _supabase;
  final MapsService _maps;

  TripController({
    SupabaseService? supabase,
    MapsService? maps,
  })  : _supabase = supabase ?? const SupabaseService(),
        _maps = maps ?? const MapsService();

  Future<List<TripModel>> getTrips(String userId) {
    return _supabase.getTripsForUser(userId);
  }

  Future<void> markCompleted({required String tripId}) async {
    await _supabase.updateTripStatus(tripId: tripId, status: 'completed');
  }

  /// Placeholder for updating a driver's live location for the trip.
  Future<void> updateLiveLocation({
    required String tripId,
    required double lat,
    required double lng,
  }) async {
    // TODO: update a realtime channel / database row.
    (void,)tripId;
    (void,)lat;
    (void,)lng;
  }

  Future<List<Map<String, double>>?> getTripPolyline({
    required Map<String, double> from,
    required Map<String, double> to,
  }) async {
    return _maps.getRoutePolyline(from: from, to: to);
  }
}

