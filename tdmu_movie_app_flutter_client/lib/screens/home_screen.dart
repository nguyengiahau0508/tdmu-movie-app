import 'package:flutter/material.dart';

import '../models/auth_session.dart';
import 'admin/admin_dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.session, required this.onLogout});

  final AuthSession session;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final user = session.user;
    final tokenPreview = session.token.length > 24
        ? '${session.token.substring(0, 24)}...'
        : session.token;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TDMU Movie App'),
        actions: [
          IconButton(
            onPressed: () async {
              await onLogout();
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xin chào, ${user.username}!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text('Email: ${user.email}'),
                    Text('Vai trò: ${user.role}'),
                    const SizedBox(height: 12),
                    if (user.role == 'admin')
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdminDashboardScreen(session: session),
                            ),
                          );
                        },
                        icon: const Icon(Icons.admin_panel_settings_outlined),
                        label: const Text('Vào trang quản trị'),
                      ),
                    if (user.role == 'admin') const SizedBox(height: 12),
                    const Text('JWT Token (rút gọn):'),
                    SelectableText(tokenPreview),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
