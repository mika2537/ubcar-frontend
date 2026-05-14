import '../models/chat_message_model.dart';
import '../models/trip_model.dart';
import '../models/discover_route_model.dart';
import '../models/route_model.dart';
import '../models/user_model.dart';
import '../services/maps_service.dart';
import '../services/backend_api_service.dart';

class PassengerController {
  final BackendApiService _api;
  final MapsService _maps;

  PassengerController({BackendApiService? api, MapsService? maps})
    : _api = api ?? BackendApiService(),
      _maps = maps ?? const MapsService();

  Future<List<RouteModel>> getSavedRoutes(String passengerId) async {
    return _api.getSavedRoutes(passengerId);
  }

  Future<List<TripModel>> getPassengerTrips(String passengerId) async {
    return _api.getTripsForUser(passengerId);
  }

  Future<List<DiscoverRouteModel>> discoverRoutes() async {
    return _api.discoverRoutes();
  }

  Future<UserModel?> getUserProfile(String userId) async {
    return _api.getUserProfile(userId);
  }

  Future<TripModel?> createTrip({
    required String passengerId,
    required RouteModel route,
  }) async {
    return _api.createTrip(passengerId: passengerId, route: route);
  }

  Future<void> cancelTrip({required String tripId}) async {
    await _api.updateTripStatus(tripId: tripId, status: 'cancelled');
  }

  Future<void> saveRoute({
    required String passengerId,
    required RouteModel route,
  }) async {
    await _api.saveRoute(userId: passengerId, route: route);
  }

  Future<List<Map<String, double>>?> geocodeAddress(String query) async {
    return _maps.geocode(query);
  }

  Future<void> sendChat({
    required String tripId,
    required String senderId,
    required String message,
  }) async {
    await _api.sendChatMessage(
      tripId: tripId,
      senderId: senderId,
      message: message,
    );
  }

  Future<List<ChatMessageModel>> loadChat({required String tripId}) async {
    return _api.getChatMessages(tripId: tripId);
  }
}
