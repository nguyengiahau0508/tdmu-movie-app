import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class PaymentService {
  PaymentService({required this.token, http.Client? client})
      : _client = client ?? http.Client();

  final String token;
  final http.Client _client;
  final String _baseUrl = ApiConfig.baseUrl;

  Future<String> createMoMoPayment({
    required double amount,
    required int packageMonths,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/payment/momo/create'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'amount': amount,
        'package_months': packageMonths,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded['success'] == true && decoded['payUrl'] != null) {
        return decoded['payUrl'];
      }
      throw Exception(decoded['message'] ?? 'Lỗi khi tạo thanh toán MoMo.');
    }

    throw Exception('Lỗi kết nối máy chủ khi tạo thanh toán.');
  }
}
