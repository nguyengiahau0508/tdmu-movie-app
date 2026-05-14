import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../models/admin_episode.dart';
import '../models/auth_session.dart';
import '../models/watchlist_item.dart';
import '../models/review.dart';
import '../services/movie_service.dart';
import '../services/user_service.dart';
import '../utils/url_utils.dart';
import 'watch_movie_screen.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({
    super.key,
    required this.movie,
    required this.session,
    required this.movieService,
    required this.userService,
  });

  final Movie movie;
  final AuthSession session;
  final MovieService movieService;
  final UserService userService;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  late Movie _movie;
  List<AdminEpisode> _episodes = [];
  List<Review> _reviews = [];
  WatchlistItem? _watchlistItem;
  bool _loading = true;
  bool _isFavoriteLoading = false;
  bool _isReviewSubmitting = false;

  final _commentController = TextEditingController();
  int _selectedRating = 10;

  @override
  void initState() {
    super.initState();
    _movie = widget.movie;
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // 1. Tải thông tin phim, tập phim và đánh giá (Ưu tiên cao)
      final results = await Future.wait([
        widget.movieService.fetchMovieDetail(_movie.id),
        widget.movieService.fetchEpisodes(_movie.id),
        widget.userService.fetchReviews(_movie.id),
      ]);
      
      if (mounted) {
        setState(() {
          _movie = results[0] as Movie;
          _episodes = results[1] as List<AdminEpisode>;
          _reviews = results[2] as List<Review>;
          _loading = false; // Đã có đủ thông tin để hiển thị nội dung chính
        });
      }

      // 2. Tải danh sách yêu thích sau (Ưu tiên thấp hơn, không làm chết màn hình)
      try {
        final watchlist = await widget.userService.fetchWatchlist(widget.session.token);
        if (mounted) {
          setState(() {
            _watchlistItem = watchlist.cast<WatchlistItem?>().firstWhere(
              (item) => item?.movieId == _movie.id,
              orElse: () => null,
            );
          });
        }
      } catch (e) {
        // Chỉ hiện thông báo lỗi cho riêng phần yêu thích, không chặn hiển thị phim
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lưu ý: ${e.toString()}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted && _loading) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isFavoriteLoading = true);
    try {
      if (_watchlistItem != null) {
        await widget.userService.removeFromWatchlist(
          widget.session.token,
          _watchlistItem!.id,
        );
        setState(() => _watchlistItem = null);
      } else {
        await widget.userService.addToWatchlist(
          widget.session.token,
          _movie.id,
        );
        // Reload watchlist to get the new ID
        final watchlist = await widget.userService.fetchWatchlist(widget.session.token);
        setState(() {
          _watchlistItem = watchlist.cast<WatchlistItem?>().firstWhere(
            (item) => item?.movieId == _movie.id,
            orElse: () => null,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isFavoriteLoading = false);
    }
  }

  Future<void> _saveProgress(AdminEpisode episode) async {
    try {
      // Giả lập lưu tiến độ khi người dùng nhấn xem
      // Trong thực tế, việc này sẽ được gọi từ Player khi người dùng xem xong hoặc thoát player
      await widget.userService.saveWatchProgress(
        token: widget.session.token,
        movieId: _movie.id,
        episodeId: episode.id,
        watchedSeconds: 0, // Bắt đầu xem
        durationSeconds: episode.duration ?? 0,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã lưu tiến độ xem cho: ${episode.title}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lưu tiến độ: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _submitReview() async {
    if (_isReviewSubmitting) return;

    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập bình luận.')),
      );
      return;
    }

    setState(() => _isReviewSubmitting = true);
    try {
      await widget.userService.submitReview(
        token: widget.session.token,
        movieId: _movie.id,
        rating: _selectedRating,
        comment: _commentController.text.trim(),
      );

      _commentController.clear();
      // Tải lại danh sách đánh giá
      final reviews = await widget.userService.fetchReviews(_movie.id);
      if (mounted) {
        setState(() => _reviews = reviews);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cảm ơn bạn đã đánh giá!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi đánh giá: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isReviewSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildHeader(),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Theme.of(context).primaryColor,
                    tabs: const [
                      Tab(text: 'Thông tin'),
                      Tab(text: 'Đánh giá'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              // Tab 1: Thông tin
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDescription(),
                    const SizedBox(height: 24),
                    _buildEpisodeList(),
                  ],
                ),
              ),
              // Tab 2: Đánh giá
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: _buildReviewSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      actions: [
        _isFavoriteLoading
            ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              )
            : IconButton(
                onPressed: _toggleFavorite,
                icon: Icon(
                  _watchlistItem != null ? Icons.favorite : Icons.favorite_border,
                  color: _watchlistItem != null ? Colors.red : Colors.white,
                ),
                tooltip: _watchlistItem != null ? 'Xoá khỏi yêu thích' : 'Thêm vào yêu thích',
              ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (_movie.backdropUrl != null)
              Image.network(
                UrlUtils.normalizeUrl(_movie.backdropUrl),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.black),
              )
            else
              Container(color: Colors.black),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 120,
            height: 180,
            child: _movie.posterUrl != null
                ? Image.network(
                    UrlUtils.normalizeUrl(_movie.posterUrl),
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
                _movie.title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _movie.genres.map((g) => _buildGenreChip(g.name)).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${_movie.ratingAvg ?? 0.0}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${_movie.releaseYear ?? 'N/A'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Loại: ${_movie.type == 'series' ? 'Phim bộ' : 'Phim lẻ'}',
                style: const TextStyle(color: Colors.grey),
              ),
              if (_movie.country != null)
                Text(
                  'Quốc gia: ${_movie.country}',
                  style: const TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenreChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nội dung',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _movie.description ?? 'Đang cập nhật nội dung...',
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildEpisodeList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_episodes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text('Chưa có tập phim nào.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _movie.type == 'series' ? 'Danh sách tập' : 'Xem phim',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _episodes.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final episode = _episodes[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 100,
                  height: 60,
                  child: episode.thumbnailUrl != null
                      ? Image.network(
                          UrlUtils.normalizeUrl(episode.thumbnailUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.grey),
                        )
                      : Container(color: Colors.grey),
                ),
              ),
              title: Text('Tập ${episode.episodeNumber}: ${episode.title}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (episode.duration != null)
                    Text('${episode.duration} phút', style: const TextStyle(fontSize: 12)),
                  if (episode.description != null)
                    Text(
                      episode.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WatchMovieScreen(
                      movie: _movie,
                      episode: episode,
                      session: widget.session,
                      userService: widget.userService,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Form đánh giá
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Để lại đánh giá của bạn:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Điểm: '),
                  DropdownButton<int>(
                    value: _selectedRating,
                    items: List.generate(10, (i) => 10 - i)
                        .map((v) => DropdownMenuItem(value: v, child: Text('$v sao')))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedRating = v ?? 10),
                  ),
                ],
              ),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Nhập bình luận ngắn...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isReviewSubmitting ? null : _submitReview,
                  child: _isReviewSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Gửi đánh giá'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Danh sách đánh giá
        if (_reviews.isEmpty)
          const Text('Chưa có đánh giá nào cho phim này.', style: TextStyle(color: Colors.grey))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final review = _reviews[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          review.user?.username ?? 'Người dùng',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            Text(' ${review.rating}/10'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (review.comment != null && review.comment!.isNotEmpty)
                      Text(review.comment!),
                    const SizedBox(height: 4),
                    Text(
                      '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
