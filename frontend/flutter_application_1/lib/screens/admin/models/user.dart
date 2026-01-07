class User {
  final String id;
  final String name;
  final String? avatarUrl;
  final String role;

  User({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.role,
  });
}
