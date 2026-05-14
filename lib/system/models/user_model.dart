class UserModel {
  final String id;
  final String? name;
  final String email;
  final String role; // 'driver' | 'passenger'
  final String? phone;
  final String? gender;
  final int? age;
  final String? carModel;
  final String? carPlate;
  final String? driverLicenseId;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    this.name,
    required this.email,
    required this.role,
    this.phone,
    this.gender,
    this.age,
    this.carModel,
    this.carPlate,
    this.driverLicenseId,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    int? parseAge(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      phone: json['phone'] as String?,
      gender: json['gender'] as String?,
      age: parseAge(json['age']),
      carModel: (json['carModel'] ?? json['car_model']) as String?,
      carPlate: (json['carPlate'] ?? json['car_plate']) as String?,
      driverLicenseId:
          (json['driverLicenseId'] ?? json['driver_license_id']) as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}
