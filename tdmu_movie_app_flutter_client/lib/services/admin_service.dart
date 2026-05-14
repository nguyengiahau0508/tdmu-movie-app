import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/admin_episode.dart';
import '../models/admin_genre.dart';
import '../models/movie.dart';
import '../utils/upload_file_picker.dart';

class AdminService {
  AdminService({required this.token, http.Client? client})
    : _client = client ?? http.Client();

  final String token;
  final http.Client _client;
  final String _baseUrl = ApiConfig.baseUrl;

  Future<List<Movie>> fetchMovies() async {
    final response = await _client.get(Uri.parse('$_baseUrl/movies'));
    final list = _asList(response);
    return list.map(Movie.fromJson).toList();
  }

  Future<List<AdminGenre>> fetchGenres() async {
    final response = await _client.get(Uri.parse('$_baseUrl/genres'));
    final list = _asList(response);
    return list.map(AdminGenre.fromJson).toList();
  }

  Future<List<AdminEpisode>> fetchEpisodes() async {
    final response = await _client.get(Uri.parse('$_baseUrl/episodes'));
    final list = _asList(response);
    return list.map(AdminEpisode.fromJson).toList();
  }

  Future<void> createMovie(Map<String, dynamic> payload) async {
    await _authorizedMultipartRequest(
      method: 'POST',
      path: '/admin/movies',
      fields: _normalizeFields(payload),
      files: _extractFiles(payload),
    );
  }

  Future<void> updateMovie(int id, Map<String, dynamic> payload) async {
    final fields = _normalizeFields(payload);
    fields['_method'] = 'PUT';
    await _authorizedMultipartRequest(
      method: 'POST',
      path: '/admin/movies/$id',
      fields: fields,
      files: _extractFiles(payload),
    );
  }

  Future<void> deleteMovie(int id) async {
    await _authorizedJsonRequest('DELETE', '/admin/movies/$id', null);
  }

  Future<void> createGenre(Map<String, dynamic> payload) async {
    await _authorizedJsonRequest('POST', '/admin/genres', payload);
  }

  Future<void> updateGenre(int id, Map<String, dynamic> payload) async {
    await _authorizedJsonRequest('PUT', '/admin/genres/$id', payload);
  }

  Future<void> deleteGenre(int id) async {
    await _authorizedJsonRequest('DELETE', '/admin/genres/$id', null);
  }

  Future<void> createEpisode(Map<String, dynamic> payload) async {
    await _authorizedMultipartRequest(
      method: 'POST',
      path: '/admin/episodes',
      fields: _normalizeFields(payload),
      files: _extractFiles(payload),
    );
  }

  Future<void> updateEpisode(int id, Map<String, dynamic> payload) async {
    final fields = _normalizeFields(payload);
    fields['_method'] = 'PUT';
    await _authorizedMultipartRequest(
      method: 'POST',
      path: '/admin/episodes/$id',
      fields: fields,
      files: _extractFiles(payload),
    );
  }

  Future<void> deleteEpisode(int id) async {
    await _authorizedJsonRequest('DELETE', '/admin/episodes/$id', null);
  }

  Future<void> _authorizedJsonRequest(
    String method,
    String path,
    Map<String, dynamic>? payload,
  ) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    late http.Response response;

    switch (method) {
      case 'POST':
        response = await _client.post(
          uri,
          headers: headers,
          body: jsonEncode(payload),
        );
        break;
      case 'PUT':
        response = await _client.put(
          uri,
          headers: headers,
          body: jsonEncode(payload),
        );
        break;
      case 'DELETE':
        response = await _client.delete(uri, headers: headers);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractError(response.body, fallback: 'Yêu cầu quản trị thất bại.'),
      );
    }
  }

  Future<void> _authorizedMultipartRequest({
    required String method,
    required String path,
    required Map<String, String> fields,
    required Map<String, PickedUploadFile> files,
  }) async {
    final request = http.MultipartRequest(method, Uri.parse('$_baseUrl$path'))
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $token'
      ..fields.addAll(fields);

    for (final entry in files.entries) {
      final file = entry.value;
      request.files.add(
        http.MultipartFile.fromBytes(
          entry.key,
          file.bytes,
          filename: file.name,
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractError(response.body, fallback: 'Upload tệp thất bại.'),
      );
    }
  }

  List<Map<String, dynamic>> _asList(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception(
        _extractError(response.body, fallback: 'Không tải được dữ liệu.'),
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Phản hồi API không đúng định dạng danh sách.');
    }

    return decoded.whereType<Map<String, dynamic>>().toList();
  }

  String _extractError(String body, {required String fallback}) {
    if (body.isEmpty) {
      return fallback;
    }
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        // Nếu có lỗi validation chi tiết
        if (decoded['errors'] is Map<String, dynamic>) {
          final errors = decoded['errors'] as Map<String, dynamic>;
          if (errors.isNotEmpty) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              return firstError.first.toString();
            }
          }
        }

        final message = decoded['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // Bỏ qua lỗi parse JSON
    }
    return fallback;
  }

  Map<String, String> _normalizeFields(Map<String, dynamic> payload) {
    final fields = <String, String>{};
    payload.forEach((key, value) {
      if (value == null || value is PickedUploadFile) {
        return;
      }
      if (value is bool) {
        fields[key] = value ? '1' : '0';
        return;
      }
      if (value is List) {
        for (var i = 0; i < value.length; i++) {
          fields['$key[$i]'] = '${value[i]}';
        }
        return;
      }
      if (value is Map) {
        value.forEach((k, v) {
          fields['$key[$k]'] = '$v';
        });
        return;
      }
      fields[key] = '$value';
    });
    return fields;
  }

  Map<String, PickedUploadFile> _extractFiles(Map<String, dynamic> payload) {
    final files = <String, PickedUploadFile>{};
    payload.forEach((key, value) {
      if (value is PickedUploadFile) {
        files[key] = value;
      }
    });

    // Xử lý các file chất lượng được gắn label
    payload.forEach((key, value) {
      if (key.startsWith('quality_file_') && value is PickedUploadFile) {
        files[key] = value;
      }
    });
    
    return files;
  }
}
