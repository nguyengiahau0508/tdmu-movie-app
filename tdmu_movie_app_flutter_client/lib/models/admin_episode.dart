class AdminEpisode {
  const AdminEpisode({
    required this.id,
    required this.movieId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.title,
    required this.videoUrl,
    required this.thumbnailUrl,
  });

  final int id;
  final int movieId;
  final int seasonNumber;
  final int episodeNumber;
  final String title;
  final String videoUrl;
  final String? thumbnailUrl;

  factory AdminEpisode.fromJson(Map<String, dynamic> json) {
    return AdminEpisode(
      id: (json['id'] as num).toInt(),
      movieId: (json['movie_id'] as num).toInt(),
      seasonNumber: (json['season_number'] as num).toInt(),
      episodeNumber: (json['episode_number'] as num).toInt(),
      title: (json['title'] as String?) ?? '',
      videoUrl: (json['video_url'] as String?) ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
    );
  }
}
