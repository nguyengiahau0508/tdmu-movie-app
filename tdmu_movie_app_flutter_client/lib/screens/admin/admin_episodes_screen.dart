import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../models/admin_episode.dart';
import '../../models/admin_movie.dart';
import '../../services/admin_service.dart';
import '../../utils/upload_file_picker.dart';

class AdminEpisodesScreen extends StatefulWidget {
  const AdminEpisodesScreen({super.key, required this.service});

  final AdminService service;

  @override
  State<AdminEpisodesScreen> createState() => _AdminEpisodesScreenState();
}

class _AdminEpisodesScreenState extends State<AdminEpisodesScreen> {
  bool _loading = true;
  List<AdminEpisode> _episodes = const [];
  List<AdminMovie> _movies = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        widget.service.fetchEpisodes(),
        widget.service.fetchMovies(),
      ]);
      if (!mounted) return;
      setState(() {
        _episodes = results[0] as List<AdminEpisode>;
        _movies = results[1] as List<AdminMovie>;
      });
    } on Exception catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _normalizeUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    final apiBase = ApiConfig.baseUrl;
    if (apiBase.contains('10.0.2.2')) {
      return url
          .replaceAll('localhost', '10.0.2.2')
          .replaceAll('127.0.0.1', '10.0.2.2');
    }
    return url;
  }

  Future<void> _openForm([AdminEpisode? episode]) async {
    final seasonCtrl = TextEditingController(
      text: (episode?.seasonNumber ?? 1).toString(),
    );
    final episodeCtrl = TextEditingController(
      text: (episode?.episodeNumber ?? 1).toString(),
    );
    final titleCtrl = TextEditingController(text: episode?.title ?? '');
    final videoCtrl = TextEditingController(text: episode?.videoUrl ?? '');
    final thumbnailCtrl = TextEditingController(
      text: episode?.thumbnailUrl ?? '',
    );
    PickedUploadFile? videoFile;
    PickedUploadFile? thumbnailFile;
    final formKey = GlobalKey<FormState>();
    int movieId =
        episode?.movieId ?? (_movies.isNotEmpty ? _movies.first.id : 0);

    if (_movies.isEmpty) {
      _showMessage('Chưa có phim. Hãy tạo phim trước.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(episode == null ? 'Tạo tập phim' : 'Cập nhật tập phim'),
        content: Form(
          key: formKey,
          child: StatefulBuilder(
            builder: (context, setLocalState) => SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: movieId,
                      decoration: const InputDecoration(labelText: 'Phim'),
                      items: _movies
                          .map(
                            (m) => DropdownMenuItem<int>(
                              value: m.id,
                              child: Text('${m.id} - ${m.title}'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setLocalState(() => movieId = value ?? movieId),
                    ),
                    TextFormField(
                      controller: seasonCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Season'),
                      validator: (v) => int.tryParse(v ?? '') == null
                          ? 'Số không hợp lệ'
                          : null,
                    ),
                    TextFormField(
                      controller: episodeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Episode'),
                      validator: (v) => int.tryParse(v ?? '') == null
                          ? 'Số không hợp lệ'
                          : null,
                    ),
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Tiêu đề'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
                    ),
                    const Divider(height: 32),
                    TextFormField(
                      controller: videoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Video URL (để trống nếu upload file)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              final result = await pickVideoFile();
                              if (result == null) {
                                return;
                              }
                              setLocalState(() {
                                videoFile = result;
                              });
                            },
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload video'),
                          ),
                          if (videoFile != null)
                            Text(
                              videoFile!.name,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 32),
                    _imagePreview(
                      label: 'Thumbnail',
                      url: thumbnailCtrl.text,
                      file: thumbnailFile,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: thumbnailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Thumbnail URL (tùy chọn)',
                      ),
                      onChanged: (_) => setLocalState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              final result = await pickImageFile();
                              if (result == null) {
                                return;
                              }
                              setLocalState(() {
                                thumbnailFile = result;
                              });
                            },
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload thumbnail'),
                          ),
                          if (thumbnailFile != null)
                            Text(
                              thumbnailFile!.name,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    if ((videoFile == null) && videoCtrl.text.trim().isEmpty) {
      _showMessage('Bạn cần nhập Video URL hoặc upload file video.');
      return;
    }

    final payload = <String, dynamic>{
      'movie_id': movieId,
      'season_number': int.parse(seasonCtrl.text),
      'episode_number': int.parse(episodeCtrl.text),
      'title': titleCtrl.text.trim(),
      'video_url': _nullableText(videoCtrl.text),
      'thumbnail_url': _nullableText(thumbnailCtrl.text),
    };
    if (videoFile != null) {
      payload['video_file'] = videoFile!;
    }
    if (thumbnailFile != null) {
      payload['thumbnail_file'] = thumbnailFile!;
    }
    try {
      if (episode == null) {
        await widget.service.createEpisode(payload);
      } else {
        await widget.service.updateEpisode(episode.id, payload);
      }
      await _load();
    } on Exception catch (e) {
      _showMessage(e.toString());
    }
  }

  Future<void> _delete(AdminEpisode episode) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tập phim'),
        content: Text('Bạn có chắc muốn xóa "${episode.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await widget.service.deleteEpisode(episode.id);
      await _load();
    } on Exception catch (e) {
      _showMessage(e.toString());
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text.replaceFirst('Exception: ', ''))),
    );
  }

  String? _nullableText(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  String _movieTitle(int id) {
    for (final movie in _movies) {
      if (movie.id == id) {
        return movie.title;
      }
    }

    return 'Movie #$id';
  }

  Widget _imagePreview({
    required String label,
    required String? url,
    required PickedUploadFile? file,
  }) {
    Widget? image;
    if (file != null) {
      image = Image.memory(
        Uint8List.fromList(file.bytes),
        fit: BoxFit.cover,
      );
    } else if (url != null && url.isNotEmpty) {
      image = Image.network(
        _normalizeUrl(url),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: image != null
              ? ClipRRect(borderRadius: BorderRadius.circular(8), child: image)
              : const Center(child: Icon(Icons.image, color: Colors.grey)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRUD tập phim'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: () => _openForm(), icon: const Icon(Icons.add)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: _episodes.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final episode = _episodes[index];
                final thumbnailUrl = _normalizeUrl(episode.thumbnailUrl);

                return ListTile(
                  leading: Container(
                    width: 60,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: thumbnailUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.broken_image, size: 20),
                            ),
                          )
                        : const Icon(Icons.slideshow, color: Colors.grey),
                  ),
                  title: Text(episode.title),
                  subtitle: Text(
                    '${_movieTitle(episode.movieId)} | S${episode.seasonNumber}E${episode.episodeNumber}',
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        onPressed: () => _openForm(episode),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () => _delete(episode),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
