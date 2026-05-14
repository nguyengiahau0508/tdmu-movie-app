import 'auth_user.dart';

class Review {
  final int id;
  final int userId;
  final int movieId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final AuthUser? user;

  const Review({
    required this.id,
    required this.userId,
    required this.movieId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.user,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      movieId: (json['movie_id'] as num).toInt(),
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      user: json['user'] != null ? AuthUser.fromJson(json['user']) : null,
    );
  }
}
