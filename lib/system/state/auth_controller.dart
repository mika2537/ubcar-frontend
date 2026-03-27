import '../models/user_model.dart';
import '../services/supabase_service.dart';

class AuthController {
  final SupabaseService _supabase;

  AuthController({SupabaseService? supabase})
      : _supabase = supabase ?? const SupabaseService();

  /// In a real app, this should be derived from auth state.
  bool get isLoggedIn => false;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _supabase.signInWithEmail(email: email, password: password);
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    await _supabase.signUpWithEmail(email: email, password: password);
  }

  Future<UserModel?> getCurrentUser() async {
    return _supabase.getCurrentUser();
  }

  Future<String?> getRole() async {
    return _supabase.getCurrentUserRole();
  }

  Future<void> signOut() async {
    await _supabase.signOut();
  }
}

