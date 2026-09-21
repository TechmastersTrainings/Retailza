class UserModel {
  final int id;
  final String? mobileNumber;
  final String? email;
  final String? name;
  final String role;
  final bool isActive;

  UserModel({
    required this.id,
    this.mobileNumber,
    this.email,
    this.name,
    required this.role,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      mobileNumber: json['mobile_number'] as String?,
      email: json['email'] as String?,
      name: json['name'] as String?,
      role: json['role'] as String? ?? 'OWNER',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mobile_number': mobileNumber,
      'email': email,
      'name': name,
      'role': role,
      'is_active': isActive,
    };
  }
}
