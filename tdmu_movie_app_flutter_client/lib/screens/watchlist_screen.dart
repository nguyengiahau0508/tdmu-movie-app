import 'package:flutter/material.dart';

import '../models/auth_session.dart';
import '../models/watchlist_item.dart';
import '../services/movie_service.dart';
import '../services/user_service.dart';
import '../utils/url_utils.dart';
import 'movie_detail_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({
    super.key,
    required this.session,
    required this.userService,
    required this.movieService,
  });

  final AuthSession session;
  final UserService userService;
  final MovieService movieService;

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  List<WatchlistItem> _watchlist = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
  }

  Future<void> _loadWatchlist() async {
    setState(() => _loading = true);
    try {
      final watchlist = await widget.userService.fetchWatchlist(widget.session.token);
      if (mounted) {
        setState(() {
          _watchlist = watchlist;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách yêu thích: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phim yêu thích'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _watchlist.isEmpty
              ? const Center(child: Text('Danh sách yêu thích trống.'))
              : RefreshIndicator(
                  onRefresh: _loadWatchlist,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.6,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _watchlist.length,
                    itemBuilder: (context, index) {
                      final movie = _watchlist[index].movie;
                      if (movie == null) return const SizedBox.shrink();

                      return Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
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
                            ).then((_) => _loadWatchlist());
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: movie.posterUrl != null
                                    ? Image.network(
                                        UrlUtils.normalizeUrl(movie.posterUrl),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder: (_, __, ___) => Container(color: Colors.grey),
                                      )
                                    : Container(color: Colors.grey),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  movie.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
