import '../models/user_model.dart';
import '../services/backend_api_service.dart';

class AuthController {
  final BackendApiService _api;
  UserModel? _currentUser;

  AuthController({BackendApiService? api}) : _api = api ?? BackendApiService();

  /// In a real app, this should be derived from auth state.
  bool get isLoggedIn => _currentUser != null;

  Future<void> signIn({required String email, required String password}) async {
    await _api.signIn(email: email, password: password);
    _currentUser = await _api.getCurrentUser();
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
    await _api.signUp(
      name: name,
      email: email,
      password: password,
      role: role,
      phone: phone,
      gender: gender,
      age: age,
      carModel: carModel,
      carPlate: carPlate,
      driverLicenseId: driverLicenseId,
    );
    _currentUser = await _api.getCurrentUser();
  }

  Future<void> forgotPassword({
    required String email,
    required String newPassword,
  }) async {
    await _api.forgotPassword(email: email, newPassword: newPassword);
  }

  Future<void> signInWithGoogle({
    required String role,
    required String idToken,
  }) async {
    await _api.signInWithGoogle(role: role, idToken: idToken);
    _currentUser = await _api.getCurrentUser();
  }

  Future<UserModel?> getCurrentUser() async {
    _currentUser = await _api.getCurrentUser();
    return _currentUser;
  }

  Future<String?> getRole() async {
    return _api.getCurrentUserRole();
  }

  Future<void> signOut() async {
    await _api.signOut();
    _currentUser = null;
  }
}
