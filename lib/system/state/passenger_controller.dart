import '../models/trip_model.dart';
import '../models/route_model.dart';
import '../services/maps_service.dart';
import '../services/supabase_service.dart';

class PassengerController {
  final SupabaseService _supabase;
  final MapsService _maps;

  PassengerController({
    SupabaseService? supabase,
    MapsService? maps,
  })  : _supabase = supabase ?? const SupabaseService(),
        _maps = maps ?? const MapsService();

  Future<List<RouteModel>> getSavedRoutes(String passengerId) async {
    return _supabase.getSavedRoutes(passengerId);
  }

  Future<TripModel?> createTrip({
    required String passengerId,
    required RouteModel route,
  }) async {
    return _supabase.createTrip(passengerId: passengerId, route: route);
  }

  Future<void> cancelTrip({required String tripId}) async {
    await _supabase.updateTripStatus(tripId: tripId, status: 'cancelled');
  }

  Future<void> saveRoute({
    required String passengerId,
    required RouteModel route,
  }) async {
    await _supabase.saveRoute(userId: passengerId, route: route);
  }

  Future<List<Map<String, double>>?> geocodeAddress(String query) async {
    return _maps.geocode(query);
  }

  Future<void> sendChat({
    required String tripId,
    required String senderId,
    required String message,
  }) async {
    await _supabase.sendChatMessage(
      tripId: tripId,
      senderId: senderId,
      message: message,
    );
  }

  Future<List<String>> loadChat({
    required String tripId,
  }) async {
    return _supabase.getChatMessages(tripId: tripId);
  }
}

