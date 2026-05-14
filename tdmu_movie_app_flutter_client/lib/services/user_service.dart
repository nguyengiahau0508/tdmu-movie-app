import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/watchlist_item.dart';
import '../models/watch_history_item.dart';
import '../models/review.dart';

class UserService {
  UserService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final String _baseUrl = ApiConfig.baseUrl;

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // --- Watchlist ---

  Future<List<WatchlistItem>> fetchWatchlist(String token) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/watchlists'),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Không tải được danh sách yêu thích (Status: ${response.statusCode}).');
    }

    final List<dynamic> list = jsonDecode(response.body);
    return list.map((json) => WatchlistItem.fromJson(json)).toList();
  }

  Future<void> addToWatchlist(String token, int movieId) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/watchlists'),
      headers: _headers(token),
      body: jsonEncode({'movie_id': movieId}),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Không thể thêm vào danh sách yêu thích (Status: ${response.statusCode}).');
    }
  }

  Future<void> removeFromWatchlist(String token, int watchlistId) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/watchlists/$watchlistId'),
      headers: _headers(token),
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Không thể xoá khỏi danh sách yêu thích (Status: ${response.statusCode}).');
    }
  }

  // --- Watch History ---

  Future<List<WatchHistoryItem>> fetchWatchHistory(String token) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/watch-history'),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Không tải được lịch sử xem (Status: ${response.statusCode}).');
    }

    final List<dynamic> list = jsonDecode(response.body);
    return list.map((json) => WatchHistoryItem.fromJson(json)).toList();
  }

  Future<void> saveWatchProgress({
    required String token,
    required int movieId,
    int? episodeId,
    required int watchedSeconds,
    required int durationSeconds,
    bool isFinished = false,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/watch-history'),
      headers: _headers(token),
      body: jsonEncode({
        'movie_id': movieId,
        'episode_id': episodeId,
        'watched_seconds': watchedSeconds,
        'duration_seconds': durationSeconds,
        'is_finished': isFinished,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Không thể lưu tiến độ xem (Status: ${response.statusCode}).');
    }
  }

  // --- Reviews ---

  Future<List<Review>> fetchReviews(int movieId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/reviews?movie_id=$movieId'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Không tải được danh sách đánh giá (Status: ${response.statusCode}).');
    }

    final List<dynamic> list = jsonDecode(response.body);
    return list.map((json) => Review.fromJson(json)).toList();
  }

  Future<void> submitReview({
    required String token,
    required int movieId,
    required int rating,
    String? comment,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/reviews'),
      headers: _headers(token),
      body: jsonEncode({
        'movie_id': movieId,
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Không thể gửi đánh giá (Status: ${response.statusCode}).');
    }
  }
}
