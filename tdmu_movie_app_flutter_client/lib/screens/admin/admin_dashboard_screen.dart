import 'package:flutter/material.dart';

import '../../models/auth_session.dart';
import '../../services/admin_service.dart';
import 'admin_episodes_screen.dart';
import 'admin_genres_screen.dart';
import 'admin_movies_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key, required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    final service = AdminService(token: session.token);

    return Scaffold(
      appBar: AppBar(title: const Text('Quản trị hệ thống')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _AdminMenuCard(
              title: 'Quản lý phim',
              icon: Icons.movie_creation_outlined,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AdminMoviesScreen(service: service),
                  ),
                );
              },
            ),
            _AdminMenuCard(
              title: 'Quản lý tập phim',
              icon: Icons.slideshow_outlined,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AdminEpisodesScreen(service: service),
                  ),
                );
              },
            ),
            _AdminMenuCard(
              title: 'Quản lý thể loại',
              icon: Icons.category_outlined,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AdminGenresScreen(service: service),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  const _AdminMenuCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 130,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon),
                const Spacer(),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
