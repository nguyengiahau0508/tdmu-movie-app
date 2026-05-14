import 'movie.dart';

class WatchlistItem {
  final int id;
  final int userId;
  final int movieId;
  final Movie? movie;

  const WatchlistItem({
    required this.id,
    required this.userId,
    required this.movieId,
    this.movie,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      movieId: (json['movie_id'] as num).toInt(),
      movie: json['movie'] != null ? Movie.fromJson(json['movie']) : null,
    );
  }
}
