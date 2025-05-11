class User {
  final int id;
  final String username;
  final String password;
  final String role;
  final String? email;
  final String? phone;
  final String? otpCode;
  final DateTime? otpCreatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    this.email,
    this.phone,
    this.otpCode,
    this.otpCreatedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      role: map['role'],
      email: map['email'],
      phone: map['phone'],
      otpCode: map['otp_code'],
      otpCreatedAt: map['otp_created_at'] != null
          ? DateTime.tryParse(map['otp_created_at'].toString())
          : null,
      createdAt: DateTime.parse(map['created_at'].toString()),
      updatedAt: DateTime.parse(map['updated_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'email': email,
      'phone': phone,
      'otp_code': otpCode,
      'otp_created_at': otpCreatedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
