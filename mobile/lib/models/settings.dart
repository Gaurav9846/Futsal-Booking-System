class SystemSettings {
  final int id;
  final bool autoApproveOwners;
  final bool autoApproveFutsals;
  final bool maintenanceMode;
  final int bookingCancellationHours;
  final int slotLockMinutes;
  final int slotGenerationDays;
  final DateTime updatedAt;

  SystemSettings({
    required this.id,
    required this.autoApproveOwners,
    required this.autoApproveFutsals,
    required this.maintenanceMode,
    required this.bookingCancellationHours,
    required this.slotLockMinutes,
    required this.slotGenerationDays,
    required this.updatedAt,
  });

  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    return SystemSettings(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      autoApproveOwners: json['autoApproveOwners'] ?? false,
      autoApproveFutsals: json['autoApproveFutsals'] ?? false,
      maintenanceMode: json['maintenanceMode'] ?? false,
      bookingCancellationHours: json['bookingCancellationHours'] ?? 2,
      slotLockMinutes: json['slotLockMinutes'] ?? 5,
      slotGenerationDays: json['slotGenerationDays'] ?? 30,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'autoApproveOwners': autoApproveOwners,
      'autoApproveFutsals': autoApproveFutsals,
      'maintenanceMode': maintenanceMode,
      'bookingCancellationHours': bookingCancellationHours,
      'slotLockMinutes': slotLockMinutes,
      'slotGenerationDays': slotGenerationDays,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  SystemSettings copyWith({
    int? id,
    bool? autoApproveOwners,
    bool? autoApproveFutsals,
    bool? maintenanceMode,
    int? bookingCancellationHours,
    int? slotLockMinutes,
    int? slotGenerationDays,
    DateTime? updatedAt,
  }) {
    return SystemSettings(
      id: id ?? this.id,
      autoApproveOwners: autoApproveOwners ?? this.autoApproveOwners,
      autoApproveFutsals: autoApproveFutsals ?? this.autoApproveFutsals,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      bookingCancellationHours: bookingCancellationHours ?? this.bookingCancellationHours,
      slotLockMinutes: slotLockMinutes ?? this.slotLockMinutes,
      slotGenerationDays: slotGenerationDays ?? this.slotGenerationDays,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}