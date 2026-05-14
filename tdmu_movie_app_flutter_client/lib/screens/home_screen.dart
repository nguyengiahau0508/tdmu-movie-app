import 'dart:async';
import 'package:flutter/material.dart';

import '../models/auth_session.dart';
import '../models/movie.dart';
import '../models/admin_genre.dart';
import '../services/movie_service.dart';
import '../services/user_service.dart';
import '../utils/url_utils.dart';
import 'admin/admin_dashboard_screen.dart';
import 'movie_detail_screen.dart';
import 'watch_history_screen.dart';
import 'watchlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.session,
    required this.movieService,
    required this.userService,
    required this.onLogout,
  });

  final AuthSession session;
  final MovieService movieService;
  final UserService userService;
  final Future<void> Function() onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Movie> _movies = [];
  List<AdminGenre> _genres = [];
  bool _loading = true;
  String? _searchQuery;
  String? _selectedGenreSlug;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _initialLoad() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        widget.movieService.fetchGenres(),
        widget.movieService.fetchMovies(),
      ]);
      if (!mounted) return;
      setState(() {
        _genres = results[0] as List<AdminGenre>;
        _movies = results[1] as List<Movie>;
      });
    } on Exception catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshMovies() async {
    setState(() => _loading = true);
    try {
      final movies = await widget.movieService.fetchMovies(
        query: _searchQuery,
        genre: _selectedGenreSlug,
      );
      if (!mounted) return;
      setState(() => _movies = movies);
    } on Exception catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = query);
      _refreshMovies();
    });
  }

  void _onGenreSelected(String? slug) {
    setState(() => _selectedGenreSlug = slug);
    _refreshMovies();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.replaceFirst('Exception: ', ''))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TDMU Movie'),
        actions: [
          if (widget.session.user.role == 'admin')
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AdminDashboardScreen(session: widget.session),
                  ),
                );
              },
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Dashboard',
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(widget.session.user.username),
              accountEmail: Text(widget.session.user.email),
              currentAccountPicture: const CircleAvatar(
                child: Icon(Icons.person, size: 40),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Lịch sử xem'),
              onTap: () {
                Navigator.pop(context); // Đóng drawer
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WatchHistoryScreen(
                      session: widget.session,
                      userService: widget.userService,
                      movieService: widget.movieService,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Phim yêu thích'),
              onTap: () {
                Navigator.pop(context); // Đóng drawer
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WatchlistScreen(
                      session: widget.session,
                      userService: widget.userService,
                      movieService: widget.movieService,
                    ),
                  ),
                );
              },
            ),
            if (widget.session.user.role == 'admin') ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Quản trị hệ thống'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminDashboardScreen(session: widget.session),
                    ),
                  );
                },
              ),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Đăng xuất'),
              onTap: () {
                Navigator.pop(context);
                widget.onLogout();
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm phim...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          // Bộ lọc thể loại
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _genres.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _GenreChip(
                    label: 'Tất cả',
                    selected: _selectedGenreSlug == null,
                    onTap: () => _onGenreSelected(null),
                  );
                }
                final genre = _genres[index - 1];
                return _GenreChip(
                  label: genre.name,
                  selected: _selectedGenreSlug == genre.slug,
                  onTap: () => _onGenreSelected(genre.slug),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Danh sách phim
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _movies.isEmpty
                    ? const Center(child: Text('Không tìm thấy phim nào.'))
                    : RefreshIndicator(
                        onRefresh: _refreshMovies,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            int crossAxisCount = 2;
                            if (width > 1200) {
                              crossAxisCount = 6;
                            } else if (width > 900) {
                              crossAxisCount = 5;
                            } else if (width > 600) {
                              crossAxisCount = 4;
                            } else if (width > 400) {
                              crossAxisCount = 3;
                            }

                            return GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: 0.6,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: _movies.length,
                              itemBuilder: (context, index) {
                                final movie = _movies[index];
                                return _MovieCard(
                                  movie: movie,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => MovieDetailScreen(
                                          movie: movie,
                                          session: widget.session,
                                          movieService: widget.movieService,
                                          userService: widget.userService,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _MovieCard extends StatelessWidget {
  const _MovieCard({required this.movie, required this.onTap});

  final Movie movie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: movie.posterUrl != null && movie.posterUrl!.isNotEmpty
                  ? Image.network(
                      UrlUtils.normalizeUrl(movie.posterUrl),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, size: 40),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Center(child: Icon(Icons.movie, size: 40)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        '${movie.ratingAvg ?? 0.0}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const Spacer(),
                      if (movie.releaseYear != null)
                        Text(
                          '${movie.releaseYear}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
