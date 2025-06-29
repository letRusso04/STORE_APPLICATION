class User {
  final int id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final String? location;
  final String? phone;
  final String? estado;
  final String role; // ← nuevo campo obligatorio

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.location,
    this.phone,
    this.estado,
    required this.role, // ← requerido
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profileImageUrl: json['profile_image'],
      location: json['location'],
      phone: json['phone'],
      estado: json['estado'],
      role: json['role'] ?? 'user', // ← por defecto 'user'
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_image': profileImageUrl,
      'location': location,
      'phone': phone,
      'estado': estado,
      'role': role,
    };
  }

  User copyWith({
    String? name,
    String? email,
    String? profileImageUrl,
    String? location,
    String? phone,
    String? estado,
    String? role,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      location: location ?? this.location,
      phone: phone ?? this.phone,
      estado: estado ?? this.estado,
      role: role ?? this.role,
    );
  }
}
