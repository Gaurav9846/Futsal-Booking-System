class Futsal {
  final int id;
  final String name;
  final String? description;
  final String address;
  final double basePrice;
  final List<String> images;
  final double? averageRating;
  final bool isApproved;
  final int ownerId;
  final DateTime createdAt;
  final double? latitude;   // ← NEW
  final double? longitude;  // ← NEW
  double? distance;         // ← NEW (not final — calculated at runtime)

  Futsal({
    required this.id,
    required this.name,
    this.description,
    required this.address,
    required this.basePrice,
    required this.images,
    this.averageRating,
    required this.isApproved,
    required this.ownerId,
    required this.createdAt,
    this.latitude,          // ← NEW
    this.longitude,         // ← NEW
    this.distance,          // ← NEW
  });

  factory Futsal.fromJson(Map<String, dynamic> json) {
    return Futsal(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      description: json['description'],
      address: json['address'] ?? '',
      basePrice: json['basePrice'] is double
          ? json['basePrice']
          : double.parse(json['basePrice'].toString()),
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      averageRating: json['averageRating'] != null
          ? (json['averageRating'] is double
              ? json['averageRating']
              : double.parse(json['averageRating'].toString()))
          : null,
      isApproved: json['isApproved'] ?? false,
      ownerId: json['ownerId'] is int
          ? json['ownerId']
          : int.parse(json['ownerId'].toString()),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      latitude: json['latitude'] != null          // ← NEW
          ? (json['latitude'] is double
              ? json['latitude']
              : double.tryParse(json['latitude'].toString()))
          : null,
      longitude: json['longitude'] != null        // ← NEW
          ? (json['longitude'] is double
              ? json['longitude']
              : double.tryParse(json['longitude'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'basePrice': basePrice,
      'images': images,
      'averageRating': averageRating,
      'isApproved': isApproved,
      'ownerId': ownerId,
      'createdAt': createdAt.toIso8601String(),
      'latitude': latitude,     // ← NEW
      'longitude': longitude,   // ← NEW
    };
  }
}