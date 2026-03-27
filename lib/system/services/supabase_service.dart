import '../models/trip_model.dart';
import '../models/user_model.dart';
import '../models/route_model.dart';

/// Placeholder for Supabase access layer.
///
/// Methods here return `null`/empty placeholders until you wire Supabase SDK.
class SupabaseService {
  const SupabaseService();

  // ---------------- Auth ----------------
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    // TODO: implement sign-in.
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    // TODO: implement sign-up.
  }

  Future<void> signOut() async {
    // TODO: implement sign-out.
  }

  Future<UserModel?> getCurrentUser() async {
    // TODO: fetch current user.
    return null;
  }

  Future<String?> getCurrentUserRole() async {
    final user = await getCurrentUser();
    return user?.role;
  }

  // --------------- Rides/Trips ---------------
  Future<TripModel?> createTrip({
    required String passengerId,
    required RouteModel route,
  }) async {
    // TODO: create trip row.
    return null;
  }

  Future<List<TripModel>> getTripsForUser(String userId) async {
    // TODO: fetch trips for driver/passenger.
    return const [];
  }

  Future<void> updateTripStatus({
    required String tripId,
    required String status,
  }) async {
    // TODO: update status.
  }

  // ---------------- Routes ----------------
  Future<List<RouteModel>> getSavedRoutes(String userId) async {
    // TODO: fetch saved routes.
    return const [];
  }

  Future<void> saveRoute({
    required String userId,
    required RouteModel route,
  }) async {
    // TODO: insert saved route.
  }

  // ---------------- Chat ----------------
  Future<void> sendChatMessage({
    required String tripId,
    required String senderId,
    required String message,
  }) async {
    // TODO: insert chat message.
  }

  Future<List<String>> getChatMessages({
    required String tripId,
  }) async {
    // TODO: fetch messages.
    return const [];
  }
}

