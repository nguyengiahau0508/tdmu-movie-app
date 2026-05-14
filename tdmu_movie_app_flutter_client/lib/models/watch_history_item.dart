import 'movie.dart';
import 'admin_episode.dart';

class WatchHistoryItem {
  final int id;
  final int userId;
  final int movieId;
  final int? episodeId;
  final int watchedSeconds;
  final int durationSeconds;
  final bool isFinished;
  final DateTime updatedAt;
  final Movie? movie;
  final AdminEpisode? episode;

  const WatchHistoryItem({
    required this.id,
    required this.userId,
    required this.movieId,
    this.episodeId,
    required this.watchedSeconds,
    required this.durationSeconds,
    required this.isFinished,
    required this.updatedAt,
    this.movie,
    this.episode,
  });

  factory WatchHistoryItem.fromJson(Map<String, dynamic> json) {
    return WatchHistoryItem(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      movieId: (json['movie_id'] as num).toInt(),
      episodeId: (json['episode_id'] as num?)?.toInt(),
      watchedSeconds: (json['watched_seconds'] as num).toInt(),
      durationSeconds: (json['duration_seconds'] as num).toInt(),
      isFinished: json['is_finished'] == true || json['is_finished'] == 1,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      movie: json['movie'] != null ? Movie.fromJson(json['movie']) : null,
      episode: json['episode'] != null ? AdminEpisode.fromJson(json['episode']) : null,
    );
  }
}
