class ProviderModel {
  final String id;
  final String userName;
  final String email;
  final String? imageUrl;
  final String role;

  ProviderModel({
    required this.id,
    required this.userName,
    required this.email,
    this.imageUrl,
    required this.role,
  });

  // تحويل من JSON (يستخدم عند تسجيل الدخول)
  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id: json['_id'] ?? json['id'] ?? '',
      userName: json['userName'] ?? 'Unknown',
      email: json['email'] ?? '',
      imageUrl: json['imageUrl'],
      role: json['role'] ?? 'vendor',
    );
  }

  // تحويل إلى Map (للحفظ)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'userName': userName,
      'email': email,
      'imageUrl': imageUrl,
      'role': role,
    };
  }
}