class UserModel {
  final String id;
  final String email;
  final String role; // 'driver' | 'passenger'

  const UserModel({
    required this.id,
    required this.email,
    required this.role,
  });
}

