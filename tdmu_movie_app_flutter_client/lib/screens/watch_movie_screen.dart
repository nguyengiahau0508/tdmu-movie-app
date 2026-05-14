import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../models/movie.dart';
import '../models/admin_episode.dart';
import '../models/auth_session.dart';
import '../models/watch_history_item.dart';
import '../services/user_service.dart';
import '../utils/url_utils.dart';

class WatchMovieScreen extends StatefulWidget {
  const WatchMovieScreen({
    super.key,
    required this.movie,
    required this.episode,
    required this.session,
    required this.userService,
  });

  final Movie movie;
  final AdminEpisode episode;
  final AuthSession session;
  final UserService userService;

  @override
  State<WatchMovieScreen> createState() => _WatchMovieScreenState();
}

class _WatchMovieScreenState extends State<WatchMovieScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _loading = true;
  Timer? _progressTimer;
  WatchHistoryItem? _historyItem;

  String? _currentQuality;
  Map<String, String> _availableQualities = {};

  @override
  void initState() {
    super.initState();
    _availableQualities = {
      'Mặc định': widget.episode.videoUrl,
      ...widget.episode.videoQualities,
    };
    _currentQuality = 'Mặc định';
    _initializePlayer();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _saveProgress(isClosing: true);
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer({Duration? startAt, bool autoPlay = true}) async {
    setState(() => _loading = true);
    try {
      if (startAt == null) {
        // 1. Lấy lịch sử xem để resume
        final historyList = await widget.userService.fetchWatchHistory(widget.session.token);
        _historyItem = historyList.cast<WatchHistoryItem?>().firstWhere(
          (h) => h?.movieId == widget.movie.id && h?.episodeId == widget.episode.id,
          orElse: () => null,
        );
      }

      // 2. Khởi tạo Video Player
      final url = _availableQualities[_currentQuality] ?? widget.episode.videoUrl;
      final videoUrl = UrlUtils.normalizeUrl(url);
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      
      await _videoPlayerController!.initialize();

      final seekPosition = startAt ?? (_historyItem != null && !_historyItem!.isFinished
          ? Duration(seconds: _historyItem!.watchedSeconds)
          : Duration.zero);

      if (seekPosition > Duration.zero) {
        await _videoPlayerController!.seekTo(seekPosition);
      }

      // 3. Khởi tạo Chewie
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: autoPlay,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        placeholder: Container(color: Colors.black),
        additionalOptions: (context) {
          if (_availableQualities.length <= 1) return [];
          return [
            OptionItem(
              onTap: (onTapContext) async {
                Navigator.pop(context); // Đóng menu options
                final selected = await showModalBottomSheet<String>(
                  context: context,
                  builder: (ctx) => ListView(
                    shrinkWrap: true,
                    children: _availableQualities.keys.map((label) {
                      return ListTile(
                        title: Text(label),
                        trailing: _currentQuality == label ? const Icon(Icons.check, color: Colors.green) : null,
                        onTap: () => Navigator.pop(ctx, label),
                      );
                    }).toList(),
                  ),
                );
                if (selected != null) {
                  _changeQuality(selected, _availableQualities[selected]!);
                }
              },
              iconData: Icons.high_quality,
              title: 'Chất lượng video',
            ),
          ];
        },
      );

      if (mounted) {
        setState(() => _loading = false);
        // Bắt đầu timer lưu tiến độ mỗi 30 giây
        _progressTimer ??= Timer.periodic(const Duration(seconds: 30), (_) => _saveProgress());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khởi tạo trình phát: $e')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _changeQuality(String label, String url) async {
    if (_currentQuality == label) return;

    final currentPosition = _videoPlayerController?.value.position;
    final isPlaying = _videoPlayerController?.value.isPlaying ?? true;
    
    final oldVideoPlayerController = _videoPlayerController;
    final oldChewieController = _chewieController;

    setState(() {
      _currentQuality = label;
      _loading = true;
      _chewieController = null;
      _videoPlayerController = null;
    });

    // Delay một chút để Flutter gỡ Chewie widget cũ khỏi cây giao diện
    await Future.delayed(const Duration(milliseconds: 50));

    oldChewieController?.dispose();
    await oldVideoPlayerController?.dispose();

    await _initializePlayer(startAt: currentPosition, autoPlay: isPlaying);
  }

  Future<void> _saveProgress({bool isClosing = false}) async {
    if (_videoPlayerController == null || !_videoPlayerController!.value.isInitialized) return;

    final position = _videoPlayerController!.value.position.inSeconds;
    final duration = _videoPlayerController!.value.duration.inSeconds;
    final isFinished = position >= duration - 5; // Coi như xong nếu còn dưới 5 giây

    try {
      await widget.userService.saveWatchProgress(
        token: widget.session.token,
        movieId: widget.movie.id,
        episodeId: widget.episode.id,
        watchedSeconds: position,
        durationSeconds: duration,
        isFinished: isFinished,
      );
    } catch (e) {
      debugPrint('Lỗi lưu tiến độ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '${widget.movie.title} - Tập ${widget.episode.episodeNumber}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_availableQualities.length > 1)
            PopupMenuButton<String>(
              icon: const Icon(Icons.settings, color: Colors.white),
              tooltip: 'Chất lượng',
              onSelected: (label) => _changeQuality(label, _availableQualities[label]!),
              itemBuilder: (context) => _availableQualities.keys.map((label) {
                return PopupMenuItem(
                  value: label,
                  child: Row(
                    children: [
                      if (_currentQuality == label)
                        const Icon(Icons.check, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(label),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                ? Chewie(controller: _chewieController!)
                : const Text('Không thể tải video', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
