import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/auth_session.dart';
import '../services/payment_service.dart';
import '../services/auth_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({
    super.key,
    required this.session,
    required this.authService,
  });

  final AuthSession session;
  final AuthService authService;

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _loading = false;
  late final PaymentService _paymentService;
  AuthSession? _currentSession;

  final List<Map<String, dynamic>> _packages = [
    {'months': 1, 'price': 50000, 'name': 'Gói 1 Tháng'},
    {'months': 6, 'price': 250000, 'name': 'Gói 6 Tháng (-16%)'},
    {'months': 12, 'price': 450000, 'name': 'Gói 1 Năm (-25%)'},
  ];

  @override
  void initState() {
    super.initState();
    _currentSession = widget.session;
    _paymentService = PaymentService(token: widget.session.token);
  }

  Future<void> _refreshProfile() async {
    setState(() => _loading = true);
    try {
      final user = await widget.authService.me(widget.session.token);
      final newSession = AuthSession(token: widget.session.token, user: user);
      if (mounted) {
        setState(() {
          _currentSession = newSession;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _buyPackage(int months, double price) async {
    setState(() => _loading = true);
    try {
      final payUrl = await _paymentService.createMoMoPayment(
        amount: price,
        packageMonths: months,
      );

      final uri = Uri.parse(payUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        
        // Sau khi trở về từ web/momo, hỏi user refresh
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Kiểm tra trạng thái'),
            content: const Text('Bạn đã thanh toán xong chưa? Chúng tôi sẽ cập nhật trạng thái gói cước của bạn.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _refreshProfile();
                },
                child: const Text('Tôi đã thanh toán xong'),
              ),
            ],
          ),
        );
      } else {
        throw Exception('Không thể mở trang thanh toán.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentSession!.user;
    final isVip = user.isVip;
    
    int remainingDays = 0;
    if (isVip && user.vipUntil != null) {
      remainingDays = user.vipUntil!.difference(DateTime.now()).inDays;
    }

    final allowedPackages = _packages.where((pkg) {
      int pkgDays = (pkg['months'] as int) * 30;
      return remainingDays <= pkgDays - 15;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nâng cấp VIP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProfile,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: isVip ? Colors.amber[100] : Colors.grey[200],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            isVip ? Icons.star : Icons.account_circle,
                            size: 64,
                            color: isVip ? Colors.amber[800] : Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user.username,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isVip
                                ? 'Thành viên VIP đến ngày: ${user.vipUntil?.toLocal().toString().split(' ')[0] ?? ''}'
                                : 'Tài khoản thường',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isVip ? Colors.green[700] : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Chọn gói cước',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: allowedPackages.isEmpty 
                        ? const Center(
                            child: Text('Bạn đang sử dụng gói VIP cao nhất!'),
                          )
                        : ListView.separated(
                            itemCount: allowedPackages.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final pkg = allowedPackages[index];
                        return Card(
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(pkg['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${pkg['price']} VNĐ'),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _buyPackage(pkg['months'], (pkg['price'] as int).toDouble()),
                              child: const Text('MoMo'),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
