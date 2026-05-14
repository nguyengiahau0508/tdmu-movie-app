class AdminEpisode {
  const AdminEpisode({
    required this.id,
    required this.movieId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.title,
    this.description,
    this.duration,
    required this.videoUrl,
    this.videoQualities = const {},
    required this.thumbnailUrl,
  });

  final int id;
  final int movieId;
  final int seasonNumber;
  final int episodeNumber;
  final String title;
  final String? description;
  final int? duration;
  final String videoUrl;
  final Map<String, String> videoQualities;
  final String? thumbnailUrl;

  factory AdminEpisode.fromJson(Map<String, dynamic> json) {
    final qualitiesRaw = json['video_qualities'];
    final Map<String, String> qualities = {};
    if (qualitiesRaw is Map) {
      qualitiesRaw.forEach((key, value) {
        qualities[key.toString()] = value.toString();
      });
    }

    return AdminEpisode(
      id: (json['id'] as num).toInt(),
      movieId: (json['movie_id'] as num).toInt(),
      seasonNumber: (json['season_number'] as num).toInt(),
      episodeNumber: (json['episode_number'] as num).toInt(),
      title: (json['title'] as String?) ?? '',
      description: json['description'] as String?,
      duration: (json['duration'] as num?)?.toInt(),
      videoUrl: (json['video_url'] as String?) ?? '',
      videoQualities: qualities,
      thumbnailUrl: json['thumbnail_url'] as String?,
    );
  }
}
