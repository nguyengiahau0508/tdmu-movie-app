class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.isVip = false,
    this.vipUntil,
  });

  final int id;
  final String username;
  final String email;
  final String role;
  final bool isVip;
  final DateTime? vipUntil;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      isVip: json['is_vip'] == true || json['is_vip'] == 1,
      vipUntil: json['vip_until'] != null ? DateTime.tryParse(json['vip_until'].toString()) : null,
    );
  }
}
