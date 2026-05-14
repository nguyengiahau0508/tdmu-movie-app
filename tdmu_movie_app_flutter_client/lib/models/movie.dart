import 'admin_genre.dart';

class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.posterUrl,
    required this.backdropUrl,
    required this.releaseYear,
    required this.country,
    required this.duration,
    required this.type,
    required this.ratingAvg,
    required this.ratingCount,
    required this.isPublished,
    this.genres = const [],
  });

  final int id;
  final String title;
  final String slug;
  final String? description;
  final String? posterUrl;
  final String? backdropUrl;
  final int? releaseYear;
  final String? country;
  final int? duration;
  final String type;
  final double? ratingAvg;
  final int? ratingCount;
  final bool isPublished;
  final List<AdminGenre> genres;

  factory Movie.fromJson(Map<String, dynamic> json) {
    final rawRating = json['rating_avg'];
    final rawGenres = json['genres'] as List<dynamic>?;

    return Movie(
      id: (json['id'] as num).toInt(),
      title: (json['title'] as String?) ?? '',
      slug: (json['slug'] as String?) ?? '',
      description: json['description'] as String?,
      posterUrl: json['poster_url'] as String?,
      backdropUrl: json['backdrop_url'] as String?,
      releaseYear: (json['release_year'] as num?)?.toInt(),
      country: json['country'] as String?,
      duration: (json['duration'] as num?)?.toInt(),
      type: (json['type'] as String?) ?? 'single',
      ratingAvg: rawRating is num
          ? rawRating.toDouble()
          : double.tryParse('$rawRating'),
      ratingCount: (json['rating_count'] as num?)?.toInt(),
      isPublished: json['is_published'] == true || json['is_published'] == 1,
      genres: rawGenres != null
          ? rawGenres.map((g) => AdminGenre.fromJson(g)).toList()
          : const [],
    );
  }
}
