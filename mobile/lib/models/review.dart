import 'package:flutter/material.dart';

class Review {
  final int id;
  final int userId;
  final int futsalId;
  final int bookingId;
  final double rating;
  final String? comment;
  final String? reply;
  final String userName;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.futsalId,
    required this.bookingId,
    required this.rating,
    this.comment,
    this.reply,
    required this.userName,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      futsalId: json['futsalId'] ?? 0,
      bookingId: json['bookingId'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'],
      reply: json['reply'],
      userName: json['user']?['fullName'] ?? 'Anonymous',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt']).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'futsalId': futsalId,
      'bookingId': bookingId,
      'rating': rating,
      'comment': comment,
      'reply': reply,
      'userName': userName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}