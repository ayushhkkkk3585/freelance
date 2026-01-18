class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'client' or 'buyer'
  final String? phone;
  final String? photoUrl;
  final String? bio;
  final int points;
  final List<String> cardsOwned;
  final int totalBookings;
  final double rating;
  final int reviewCount;
  final int dealCount;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.photoUrl,
    this.bio,
    this.points = 1000,
    this.cardsOwned = const [],
    this.totalBookings = 0,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.dealCount = 0,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'client',
      phone: json['phone'],
      photoUrl: json['photoUrl'],
      bio: json['bio'],
      points: json['points'] ?? 1000,
      cardsOwned: List<String>.from(json['cardsOwned'] ?? []),
      totalBookings: json['totalBookings'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      dealCount: json['dealCount'] ?? 0,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'photoUrl': photoUrl,
      'bio': bio,
      'points': points,
      'cardsOwned': cardsOwned,
      'totalBookings': totalBookings,
      'rating': rating,
      'reviewCount': reviewCount,
      'dealCount': dealCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? photoUrl,
    String? bio,
    int? points,
    List<String>? cardsOwned,
    int? totalBookings,
    double? rating,
    int? reviewCount,
    int? dealCount,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      points: points ?? this.points,
      cardsOwned: cardsOwned ?? this.cardsOwned,
      totalBookings: totalBookings ?? this.totalBookings,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      dealCount: dealCount ?? this.dealCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
