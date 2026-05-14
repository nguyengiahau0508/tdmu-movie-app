import 'package:flutter/material.dart';

import '../models/auth_session.dart';
import '../models/watch_history_item.dart';
import '../services/movie_service.dart';
import '../services/user_service.dart';
import '../utils/url_utils.dart';
import 'movie_detail_screen.dart';
import 'watch_movie_screen.dart';

class WatchHistoryScreen extends StatefulWidget {
  const WatchHistoryScreen({
    super.key,
    required this.session,
    required this.userService,
    required this.movieService,
  });

  final AuthSession session;
  final UserService userService;
  final MovieService movieService;

  @override
  State<WatchHistoryScreen> createState() => _WatchHistoryScreenState();
}

class _WatchHistoryScreenState extends State<WatchHistoryScreen> {
  List<WatchHistoryItem> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final history = await widget.userService.fetchWatchHistory(widget.session.token);
      if (mounted) {
        setState(() {
          _history = history;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải lịch sử: $e')),
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
        title: const Text('Lịch sử xem'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(child: Text('Bạn chưa xem phim nào.'))
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = _history[index];
                      final movie = item.movie;
                      if (movie == null) return const SizedBox.shrink();

                      final progress = item.durationSeconds > 0
                          ? item.watchedSeconds / item.durationSeconds
                          : 0.0;

                      return InkWell(
                        onTap: () {
                          if (item.episode != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => WatchMovieScreen(
                                  movie: movie,
                                  episode: item.episode!,
                                  session: widget.session,
                                  userService: widget.userService,
                                ),
                              ),
                            ).then((_) => _loadHistory());
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MovieDetailScreen(
                                  movie: movie,
                                  session: widget.session,
                                  movieService: widget.movieService,
                                  userService: widget.userService,
                                ),
                              ),
                            ).then((_) => _loadHistory());
                          }
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 100,
                                height: 150,
                                child: movie.posterUrl != null
                                    ? Image.network(
                                        UrlUtils.normalizeUrl(movie.posterUrl),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(color: Colors.grey),
                                      )
                                    : Container(color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    movie.title,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (item.episode != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        'Tập ${item.episode!.episodeNumber}: ${item.episode!.title}',
                                        style: const TextStyle(color: Colors.grey),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  Text(
                                    item.isFinished ? 'Đã xem xong' : 'Đang xem dở',
                                    style: TextStyle(
                                      color: item.isFinished ? Colors.green : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey[300],
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Đã xem: ${item.watchedSeconds ~/ 60} phút / ${item.durationSeconds ~/ 60} phút',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
