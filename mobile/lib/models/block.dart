class Block {
  final int id;
  final int ownerId;
  final int playerId;
  final int futsalId;
  final String? reason;
  final DateTime createdAt;
  final Map<String, dynamic>? player;  // For player details when loading
  final Map<String, dynamic>? futsal;   // For futsal details when loading

  Block({
    required this.id,
    required this.ownerId,
    required this.playerId,
    required this.futsalId,
    this.reason,
    required this.createdAt,
    this.player,
    this.futsal,
  });

  factory Block.fromJson(Map<String, dynamic> json) {
    return Block(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      ownerId: json['ownerId'] is int ? json['ownerId'] : int.parse(json['ownerId'].toString()),
      playerId: json['playerId'] is int ? json['playerId'] : int.parse(json['playerId'].toString()),
      futsalId: json['futsalId'] is int ? json['futsalId'] : int.parse(json['futsalId'].toString()),
      reason: json['reason'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      player: json['player'],
      futsal: json['futsal'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'playerId': playerId,
      'futsalId': futsalId,
      'reason': reason,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get playerName {
    if (player != null && player!['fullName'] != null) {
      return player!['fullName'];
    }
    return 'Unknown Player';
  }

  String get playerEmail {
    if (player != null && player!['email'] != null) {
      return player!['email'];
    }
    return '';
  }

  String get futsalName {
    if (futsal != null && futsal!['name'] != null) {
      return futsal!['name'];
    }
    return 'Unknown Futsal';
  }
}