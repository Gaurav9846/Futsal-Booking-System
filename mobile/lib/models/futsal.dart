class Futsal {
  final int id;
  final String name;
  final String? description;
  final String address;
  final List<String> images;
  final double? averageRating;
  final bool isApproved;  // Keep for backward compatibility
  final int ownerId;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? operatingHours;
  final List<Map<String, dynamic>>? courts;
  final String status;  // ← ADD THIS
  double? distance;

  Futsal({
    required this.id,
    required this.name,
    this.description,
    required this.address,
    required this.images,
    this.averageRating,
    required this.isApproved,
    required this.ownerId,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.operatingHours,
    this.courts,
    this.distance,
    required this.status,  // ← ADD THIS
  });

  factory Futsal.fromJson(Map<String, dynamic> json) {
    return Futsal(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      description: json['description'],
      address: json['address'] ?? '',
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
      latitude: json['latitude'] != null
          ? (json['latitude'] is double
              ? json['latitude']
              : double.tryParse(json['latitude'].toString()))
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] is double
              ? json['longitude']
              : double.tryParse(json['longitude'].toString()))
          : null,
      operatingHours: json['operatingHours'],
      courts: json['courts'] != null 
          ? List<Map<String, dynamic>>.from(json['courts']) 
          : null,
      status: json['status'] ?? 'PENDING',  // ← ADD THIS
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'images': images,
      'averageRating': averageRating,
      'isApproved': isApproved,
      'ownerId': ownerId,
      'createdAt': createdAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'operatingHours': operatingHours,
      'courts': courts,
      'status': status,  // ← ADD THIS
    };
  }

  // Helper method to get all unique amenities from courts
  List<String> getAllAmenities() {
    if (courts == null || courts!.isEmpty) return [];
    final Set<String> amenities = {};
    for (var court in courts!) {
      final courtAmenities = court['amenities'] as List?;
      if (courtAmenities != null) {
        amenities.addAll(courtAmenities.map((a) => a.toString()));
      }
    }
    return amenities.toList();
  }

  // Helper method to get court types
  List<String> getCourtTypes() {
    if (courts == null || courts!.isEmpty) return [];
    final Set<String> types = {};
    for (var court in courts!) {
      final type = court['courtType'] as String?;
      if (type != null) {
        types.add(type);
      }
    }
    return types.toList();
  }

  // Helper method to get min price
  double? getMinPrice() {
    if (courts == null || courts!.isEmpty) return null;
    double minPrice = double.infinity;
    for (var court in courts!) {
      final price = (court['basePrice'] as num?)?.toDouble();
      if (price != null && price < minPrice) {
        minPrice = price;
      }
    }
    return minPrice == double.infinity ? null : minPrice;
  }

  // Helper method to get max price
  double? getMaxPrice() {
    if (courts == null || courts!.isEmpty) return null;
    double maxPrice = 0;
    for (var court in courts!) {
      final price = (court['basePrice'] as num?)?.toDouble();
      if (price != null && price > maxPrice) {
        maxPrice = price;
      }
    }
    return maxPrice == 0 ? null : maxPrice;
  }
}