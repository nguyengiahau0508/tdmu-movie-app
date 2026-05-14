import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/movie.dart';
import '../models/admin_genre.dart';
import '../models/admin_episode.dart';

class MovieService {
  MovieService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final String _baseUrl = ApiConfig.baseUrl;

  Future<List<Movie>> fetchMovies({
    String? query,
    String? genre,
    String? type,
  }) async {
    final params = <String, String>{};
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (genre != null && genre.isNotEmpty) params['genre'] = genre;
    if (type != null && type.isNotEmpty) params['type'] = type;

    final uri = Uri.parse('$_baseUrl/movies').replace(queryParameters: params);
    final response = await _client.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Không tải được danh sách phim.');
    }

    final List<dynamic> list = jsonDecode(response.body);
    return list.map((json) => Movie.fromJson(json)).toList();
  }

  Future<Movie> fetchMovieDetail(int id) async {
    final uri = Uri.parse('$_baseUrl/movies/$id');
    final response = await _client.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Không tải được thông tin phim.');
    }

    return Movie.fromJson(jsonDecode(response.body));
  }

  Future<List<AdminEpisode>> fetchEpisodes(int movieId) async {
    final uri = Uri.parse('$_baseUrl/episodes?movie_id=$movieId');
    final response = await _client.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Không tải được danh sách tập phim.');
    }

    final List<dynamic> list = jsonDecode(response.body);
    return list.map((json) => AdminEpisode.fromJson(json)).toList();
  }

  Future<List<AdminGenre>> fetchGenres() async {
    final uri = Uri.parse('$_baseUrl/genres');
    final response = await _client.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Không tải được danh sách thể loại.');
    }

    final List<dynamic> list = jsonDecode(response.body);
    return list.map((json) => AdminGenre.fromJson(json)).toList();
  }
}
