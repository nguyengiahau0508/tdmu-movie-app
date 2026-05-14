import '../config/api_config.dart';

class UrlUtils {
  static String normalizeUrl(String? url) {
    if (url == null || url.isEmpty) return '';

    try {
      final uri = Uri.parse(url);
      final apiUri = Uri.parse(ApiConfig.baseUrl);

      Uri resultUri = uri;

      // Ensure host and port match the API base URL for local development
      if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
        resultUri = uri.replace(host: apiUri.host, port: apiUri.port);
      }

      String path = resultUri.path;
      // Redirect /storage/ requests to /api/media/ to go through Laravel's CORS middleware
      if (path.startsWith('/storage/')) {
        path = path.replaceFirst('/storage/', '/api/media/');
        resultUri = resultUri.replace(path: path);
      }

      return resultUri.toString();
    } catch (_) {
      return url ?? '';
    }
  }
}
