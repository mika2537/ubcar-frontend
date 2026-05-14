import '../models/chat_message_model.dart';
import '../models/discover_route_model.dart';
import '../models/route_model.dart';
import '../models/trip_model.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class BackendApiService {
  BackendApiService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  UserModel? _currentUser;

  Future<void> signIn({required String email, required String password}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/v1/auth/login',
      body: {'email': email, 'password': password},
      fromJson: (json) => json as Map<String, dynamic>,
      requiresAuth: false,
    );
    if (response == null) {
      throw Exception('Login failed');
    }

    final token =
        ((response['token'] as Map<String, dynamic>?)?['accessToken'])
            as String?;
    final refreshToken =
        ((response['token'] as Map<String, dynamic>?)?['refreshToken'])
            as String?;
    final userJson = response['user'] as Map<String, dynamic>?;
    if (token == null || userJson == null) {
      throw Exception('Invalid login response');
    }

    ApiClient.setAuthToken(token);
    ApiClient.setRefreshToken(refreshToken);
    _currentUser = UserModel.fromJson(userJson);
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
    required String phone,
    required String gender,
    required int age,
    String? carModel,
    String? carPlate,
    String? driverLicenseId,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/v1/auth/signup',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'phoneNumber': phone,
        'gender': gender,
        'age': age,
        'carModel': carModel,
        'carPlate': carPlate,
        'driverLicenseId': driverLicenseId,
      },
      fromJson: (json) => json as Map<String, dynamic>,
      requiresAuth: false,
    );
    if (response == null) {
      throw Exception('Sign up failed');
    }

    final token =
        ((response['token'] as Map<String, dynamic>?)?['accessToken'])
            as String?;
    final refreshToken =
        ((response['token'] as Map<String, dynamic>?)?['refreshToken'])
            as String?;
    final userJson = response['user'] as Map<String, dynamic>?;
    if (token == null || userJson == null) {
      throw Exception('Invalid signup response');
    }

    ApiClient.setAuthToken(token);
    ApiClient.setRefreshToken(refreshToken);
    _currentUser = UserModel.fromJson(userJson);
  }

  Future<void> forgotPassword({
    required String email,
    required String newPassword,
  }) async {
    await _apiClient.post<Map<String, dynamic>>(
      '/api/v1/auth/forgot-password',
      body: {'email': email, 'newPassword': newPassword},
      fromJson: (json) => json as Map<String, dynamic>,
      requiresAuth: false,
    );
  }

  Future<void> signInWithGoogle({
    required String idToken,
    required String role,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/v1/auth/google',
      body: {'id_token': idToken, 'role': role},
      fromJson: (json) => json as Map<String, dynamic>,
      requiresAuth: false,
    );
    if (response == null) {
      throw Exception('Google sign-in failed');
    }

    final token =
        ((response['token'] as Map<String, dynamic>?)?['accessToken'])
            as String?;
    final refreshToken =
        ((response['token'] as Map<String, dynamic>?)?['refreshToken'])
            as String?;
    final userJson = response['user'] as Map<String, dynamic>?;
    if (token == null || userJson == null) {
      throw Exception('Invalid Google sign-in response');
    }

    ApiClient.setAuthToken(token);
    ApiClient.setRefreshToken(refreshToken);
    _currentUser = UserModel.fromJson(userJson);
  }

  Future<void> refreshSession() async {
    final refreshToken = ApiClient.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const UnauthorizedException('Please login again');
    }

    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/v1/auth/refresh',
      body: {'refreshToken': refreshToken},
      fromJson: (json) => json as Map<String, dynamic>,
      requiresAuth: false,
    );
    final token =
        ((response?['token'] as Map<String, dynamic>?)?['accessToken'])
            as String?;
    final newRefreshToken =
        ((response?['token'] as Map<String, dynamic>?)?['refreshToken'])
            as String?;
    if (token == null) {
      throw const UnauthorizedException('Please login again');
    }

    ApiClient.setAuthToken(token);
    ApiClient.setRefreshToken(newRefreshToken);
  }

  Future<void> signOut() async {
    await _apiClient.post<Object?>('/api/v1/auth/logout');
    ApiClient.setAuthToken(null);
    ApiClient.setRefreshToken(null);
    _currentUser = null;
  }

  Future<UserModel?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/v1/auth/me',
      fromJson: (json) => json as Map<String, dynamic>,
    );
    final userJson = response?['user'] as Map<String, dynamic>?;
    if (userJson == null) {
      return null;
    }
    _currentUser = UserModel.fromJson(userJson);
    return _currentUser;
  }

  Future<String?> getCurrentUserRole() async {
    final user = await getCurrentUser();
    return user?.role;
  }

  Future<UserModel?> getUserProfile(String userId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/v1/users/$userId',
      fromJson: (json) => json as Map<String, dynamic>,
    );
    final userJson = response?['user'] as Map<String, dynamic>?;
    return userJson == null ? null : UserModel.fromJson(userJson);
  }

  Future<List<DiscoverRouteModel>> discoverRoutes() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/v1/discover/routes',
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return (response?['routes'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DiscoverRouteModel.fromJson)
        .toList();
  }

  Future<TripModel?> createTrip({
    required String passengerId,
    required RouteModel route,
    int seatsRequested = 1,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/v1/trips',
      body: {
        'passengerId': passengerId,
        'driverId': route.userId ?? '',
        'seatsRequested': seatsRequested,
        'route': {
          'id': route.id,
          'from': route.from,
          'to': route.to,
          'midpoints': route.midpoints,
        },
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
    final tripJson = response?['trip'] as Map<String, dynamic>?;
    return tripJson == null ? null : TripModel.fromJson(tripJson);
  }

  Future<TripModel?> createDemoRideRequest({
    required RouteModel route,
    required int seatsRequested,
    String passengerId = 'passenger-demo-001',
    String passengerName = 'Demo Passenger',
    double passengerRating = 4.8,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/v1/trips/demo-request',
      body: {
        'passengerId': passengerId,
        'passengerName': passengerName,
        'passengerRating': passengerRating,
        'seatsRequested': seatsRequested,
        'route': {
          'id': route.id,
          'from': route.from,
          'to': route.to,
          'midpoints': route.midpoints,
        },
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
    final tripJson = response?['trip'] as Map<String, dynamic>?;
    return tripJson == null ? null : TripModel.fromJson(tripJson);
  }

  Future<List<TripModel>> getTripsForUser(String userId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/v1/trips?userId=$userId',
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return (response?['trips'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(TripModel.fromJson)
        .toList();
  }

  Future<void> updateTripStatus({
    required String tripId,
    required String status,
  }) async {
    await _apiClient.patch<Map<String, dynamic>>(
      '/api/v1/trips/$tripId/status',
      body: {'status': status},
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<List<RouteModel>> getSavedRoutes(String userId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/v1/routes?userId=$userId',
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return (response?['routes'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(RouteModel.fromJson)
        .toList();
  }

  Future<RouteModel?> saveRoute({
    required String userId,
    required RouteModel route,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/v1/routes',
      body: {
        'userId': userId,
        'route': {
          'id': route.id,
          'from': route.from,
          'to': route.to,
          'midpoints': route.midpoints,
        },
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
    final routeJson = response?['route'] as Map<String, dynamic>?;
    return routeJson == null ? null : RouteModel.fromJson(routeJson);
  }

  Future<void> sendChatMessage({
    required String tripId,
    required String senderId,
    required String message,
  }) async {
    await _apiClient.post<Map<String, dynamic>>(
      '/api/v1/chat/$tripId',
      body: {'senderId': senderId, 'message': message},
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<List<ChatMessageModel>> getChatMessages({
    required String tripId,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/v1/chat/$tripId',
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return (response?['messages'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ChatMessageModel.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>?> getDriverLocation(String driverId) async {
    return _apiClient.get<Map<String, dynamic>>(
      '/api/v1/drivers/$driverId/location',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<UserModel?> getDriverProfile(String driverId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/v1/drivers/$driverId/profile',
      fromJson: (json) => json as Map<String, dynamic>,
    );
    final userJson = response?['driver'] as Map<String, dynamic>?;
    return userJson == null ? null : UserModel.fromJson(userJson);
  }

  Future<Map<String, dynamic>?> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
    required double heading,
  }) async {
    return _apiClient.put<Map<String, dynamic>>(
      '/api/v1/drivers/$driverId/location',
      body: {'latitude': latitude, 'longitude': longitude, 'heading': heading},
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }
}
