class Favorite {
  final int id;
  final int userId;
  final int futsalId;
  final DateTime createdAt;

  Favorite({
    required this.id,
    required this.userId,
    required this.futsalId,
    required this.createdAt,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userId: json['userId'] is int ? json['userId'] : int.parse(json['userId'].toString()),
      futsalId: json['futsalId'] is int ? json['futsalId'] : int.parse(json['futsalId'].toString()),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'futsalId': futsalId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}