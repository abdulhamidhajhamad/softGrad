class User {
  final String id;
  final String name;
  final String? avatarUrl;
  final String role;
  final String? email;

  User({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.role,
    this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['userName'] ?? json['name'] ?? 'Unknown',
      avatarUrl: json['avatar'] ?? json['avatarUrl'],
      role: json['role'] ?? 'user',
      email: json['email'],
    );
  }
}
