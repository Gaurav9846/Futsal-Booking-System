class Court {
  final int id;
  final int futsalId;
  final String courtNumber;
  final String courtType; // indoor/outdoor
  final int basePrice;
  final int? peakPrice;
  final List<String> amenities;
  final bool isActive;
  final bool isUnderMaintenance;
  final DateTime? maintenanceUntil;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Court({
    required this.id,
    required this.futsalId,
    required this.courtNumber,
    required this.courtType,
    required this.basePrice,
    this.peakPrice,
    required this.amenities,
    required this.isActive,
    required this.isUnderMaintenance,
    this.maintenanceUntil,
    this.createdAt,
    this.updatedAt,
  });

  factory Court.fromJson(Map<String, dynamic> json) {
  return Court(
    // FIX: Handle both string and integer IDs
    id: json['id'] is String ? int.parse(json['id']) : (json['id'] ?? 0),
    futsalId: json['futsalId'] is String ? int.parse(json['futsalId']) : (json['futsalId'] ?? 0),
    courtNumber: json['courtNumber']?.toString() ?? '1',
    courtType: json['courtType'] ?? 'indoor',
    basePrice: json['basePrice'] ?? 0,
    peakPrice: json['peakPrice'],
    amenities: json['amenities'] != null 
        ? List<String>.from(json['amenities']) 
        : [],
    isActive: json['isActive'] ?? true,
    isUnderMaintenance: json['isUnderMaintenance'] ?? false,
    maintenanceUntil: json['maintenanceUntil'] != null 
        ? DateTime.parse(json['maintenanceUntil']) 
        : null,
    createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : null,
    updatedAt: json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt']) 
        : null,
  );
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'futsalId': futsalId,
      'courtNumber': courtNumber,
      'courtType': courtType,
      'basePrice': basePrice,
      'peakPrice': peakPrice,
      'amenities': amenities,
      'isActive': isActive,
      'isUnderMaintenance': isUnderMaintenance,
      'maintenanceUntil': maintenanceUntil?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Copy with method for easy updates
  Court copyWith({
    int? id,
    int? futsalId,
    String? courtNumber,
    String? courtType,
    int? basePrice,
    int? peakPrice,
    List<String>? amenities,
    bool? isActive,
    bool? isUnderMaintenance,
    DateTime? maintenanceUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Court(
      id: id ?? this.id,
      futsalId: futsalId ?? this.futsalId,
      courtNumber: courtNumber ?? this.courtNumber,
      courtType: courtType ?? this.courtType,
      basePrice: basePrice ?? this.basePrice,
      peakPrice: peakPrice ?? this.peakPrice,
      amenities: amenities ?? this.amenities,
      isActive: isActive ?? this.isActive,
      isUnderMaintenance: isUnderMaintenance ?? this.isUnderMaintenance,
      maintenanceUntil: maintenanceUntil ?? this.maintenanceUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isAvailable => isActive && !isUnderMaintenance;
  
  bool get hasPeakPricing => peakPrice != null && peakPrice! > 0;
  
  int get currentPrice => hasPeakPricing ? peakPrice! : basePrice;
  
  String get courtTypeDisplay => courtType == 'indoor' ? 'Indoor' : 'Outdoor';
  
  // Get maintenance status text
  String get maintenanceStatus {
    if (!isUnderMaintenance) return 'Available';
    if (maintenanceUntil != null) {
      return 'Until ${_formatDate(maintenanceUntil!)}';
    }
    return 'Under Maintenance';
  }

  // Format date helper
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  String toString() {
    return 'Court(id: $id, number: $courtNumber, type: $courtType, price: रू$basePrice)';
  }
}

// Extension for court list operations
extension CourtListExtension on List<Court> {
  List<Court> get active => where((c) => c.isActive).toList();
  
  List<Court> get available => where((c) => c.isAvailable).toList();
  
  List<Court> get underMaintenance => where((c) => c.isUnderMaintenance).toList();
  
  List<Court> get indoor => where((c) => c.courtType == 'indoor').toList();
  
  List<Court> get outdoor => where((c) => c.courtType == 'outdoor').toList();
  
  List<Court> get withPeakPricing => where((c) => c.hasPeakPricing).toList();
  
  Court? findByNumber(String courtNumber) {
    try {
      return firstWhere((c) => c.courtNumber == courtNumber);
    } catch (e) {
      return null;
    }
  }
}