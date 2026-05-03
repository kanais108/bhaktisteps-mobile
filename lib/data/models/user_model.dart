class UserModel {
  final String id;
  final String fullName;
  final String? phone;
  final String? email;
  final String role;

  UserModel({
    required this.id,
    required this.fullName,
    this.phone,
    this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'DEVOTEE',
    );
  }
}
