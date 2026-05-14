import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../models/admin_episode.dart';
import '../../models/movie.dart';
import '../../services/admin_service.dart';
import '../../utils/upload_file_picker.dart';
import '../../utils/url_utils.dart';

class AdminMovieDetailScreen extends StatefulWidget {
  const AdminMovieDetailScreen({
    super.key,
    required this.movie,
    required this.service,
  });

  final Movie movie;
  final AdminService service;

  @override
  State<AdminMovieDetailScreen> createState() => _AdminMovieDetailScreenState();
}

class _AdminMovieDetailScreenState extends State<AdminMovieDetailScreen> {
  bool _loading = true;
  List<AdminEpisode> _episodes = [];

  @override
  void initState() {
    super.initState();
    _loadEpisodes();
  }

  Future<void> _loadEpisodes() async {
    setState(() => _loading = true);
    try {
      final all = await widget.service.fetchEpisodes();
      if (!mounted) return;
      setState(() {
        _episodes = all.where((e) => e.movieId == widget.movie.id).toList();
        _episodes.sort((a, b) {
          if (a.seasonNumber != b.seasonNumber) {
            return a.seasonNumber.compareTo(b.seasonNumber);
          }
          return a.episodeNumber.compareTo(b.episodeNumber);
        });
      });
    } on Exception catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text.replaceFirst('Exception: ', ''))),
    );
  }

  Future<void> _openEpisodeForm([AdminEpisode? episode]) async {
    final seasonCtrl = TextEditingController(text: (episode?.seasonNumber ?? 1).toString());
    final episodeCtrl = TextEditingController(text: (episode?.episodeNumber ?? (_episodes.length + 1)).toString());
    final titleCtrl = TextEditingController(text: episode?.title ?? '');
    final videoCtrl = TextEditingController(text: episode?.videoUrl ?? '');
    final thumbnailCtrl = TextEditingController(text: episode?.thumbnailUrl ?? '');
    
    List<({TextEditingController label, TextEditingController url, PickedUploadFile? file})> qualityCtrls = [];
    if (episode != null && episode.videoQualities.isNotEmpty) {
      qualityCtrls = episode.videoQualities.entries.map((e) => (
        label: TextEditingController(text: e.key),
        url: TextEditingController(text: e.value),
        file: null as PickedUploadFile?,
      )).toList();
    }

    PickedUploadFile? videoFile;
    PickedUploadFile? thumbnailFile;
    final formKey = GlobalKey<FormState>();

    void disposeAll() {
      seasonCtrl.dispose();
      episodeCtrl.dispose();
      titleCtrl.dispose();
      videoCtrl.dispose();
      thumbnailCtrl.dispose();
      for (final ctrls in qualityCtrls) {
        ctrls.label.dispose();
        ctrls.url.dispose();
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(episode == null ? 'Thêm tập phim' : 'Sửa tập phim'),
        content: Form(
          key: formKey,
          child: StatefulBuilder(
            builder: (context, setLocalState) => SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: seasonCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Season'),
                      validator: (v) => int.tryParse(v ?? '') == null ? 'Số không hợp lệ' : null,
                    ),
                    TextFormField(
                      controller: episodeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Episode'),
                      validator: (v) => int.tryParse(v ?? '') == null ? 'Số không hợp lệ' : null,
                    ),
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Tiêu đề'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
                    ),
                    const Divider(height: 32),
                    TextFormField(
                      controller: videoCtrl,
                      decoration: const InputDecoration(labelText: 'Video URL (để trống nếu upload file)'),
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
                              if (result == null) return;
                              setLocalState(() => videoFile = result);
                            },
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload video'),
                          ),
                          if (videoFile != null)
                            Text(videoFile!.name, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const Divider(height: 32),
                    Text('Chất lượng video khác (Tùy chọn)', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    ...qualityCtrls.asMap().entries.map((entry) {
                      final index = entry.key;
                      final ctrls = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      controller: ctrls.label,
                                      decoration: const InputDecoration(labelText: 'Nhãn (360p...)'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: ctrls.url,
                                      decoration: const InputDecoration(labelText: 'URL video'),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => setLocalState(() {
                                      final removed = qualityCtrls.removeAt(index);
                                      Future.delayed(const Duration(milliseconds: 300), () {
                                        removed.label.dispose();
                                        removed.url.dispose();
                                      });
                                    }),
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      final result = await pickVideoFile();
                                      if (result == null) return;
                                      setLocalState(() => qualityCtrls[index] = (
                                        label: ctrls.label,
                                        url: ctrls.url,
                                        file: result,
                                      ));
                                    },
                                    icon: const Icon(Icons.upload_file),
                                    label: const Text('Tải file lên'),
                                  ),
                                  if (ctrls.file != null)
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 8.0),
                                        child: Text(
                                          ctrls.file!.name,
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    OutlinedButton.icon(
                      onPressed: () => setLocalState(() => qualityCtrls.add((
                        label: TextEditingController(),
                        url: TextEditingController(),
                        file: null,
                      ))),
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm chất lượng'),
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
                      decoration: const InputDecoration(labelText: 'Thumbnail URL (tùy chọn)'),
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
                              if (result == null) return;
                              setLocalState(() => thumbnailFile = result);
                            },
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload thumbnail'),
                          ),
                          if (thumbnailFile != null)
                            Text(thumbnailFile!.name, style: Theme.of(context).textTheme.bodySmall),
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
            onPressed: () {
              Navigator.pop(context, false);
            },
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

    if (confirmed != true) {
      Future.delayed(const Duration(milliseconds: 300), disposeAll);
      return;
    }

    if ((videoFile == null) && videoCtrl.text.trim().isEmpty) {
      _showMessage('Bạn cần nhập Video URL hoặc upload file video.');
      disposeAll();
      return;
    }

    final payload = <String, dynamic>{
      'movie_id': widget.movie.id,
      'season_number': int.parse(seasonCtrl.text),
      'episode_number': int.parse(episodeCtrl.text),
      'title': titleCtrl.text.trim(),
      'video_url': _nullableText(videoCtrl.text),
      'thumbnail_url': _nullableText(thumbnailCtrl.text),
    };

    final Map<String, String> qualitiesMap = {};
    for (final q in qualityCtrls) {
      final label = q.label.text.trim();
      final url = q.url.text.trim();
      if (label.isNotEmpty) {
        qualitiesMap[label] = url;
        if (q.file != null) {
          payload['quality_file_${label.replaceAll(' ', '_')}'] = q.file!;
        }
      }
    }
    payload['video_qualities'] = qualitiesMap;

    Future.delayed(const Duration(milliseconds: 300), disposeAll);

    if (videoFile != null) payload['video_file'] = videoFile;
    if (thumbnailFile != null) payload['thumbnail_file'] = thumbnailFile;

    try {
      if (episode == null) {
        await widget.service.createEpisode(payload);
      } else {
        await widget.service.updateEpisode(episode.id, payload);
      }
      _loadEpisodes();
    } on Exception catch (e) {
      _showMessage(e.toString());
    }
  }

  String? _nullableText(String value) => value.trim().isEmpty ? null : value.trim();

  Future<void> _deleteEpisode(AdminEpisode ep) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tập phim'),
        content: Text('Xóa tập ${ep.episodeNumber}: ${ep.title}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.service.deleteEpisode(ep.id);
      _loadEpisodes();
    } on Exception catch (e) {
      _showMessage(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final posterUrl = UrlUtils.normalizeUrl(movie.posterUrl);
    final backdropUrl = UrlUtils.normalizeUrl(movie.backdropUrl);

    return Scaffold(
      appBar: AppBar(title: Text(movie.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (posterUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(posterUrl, height: 200, width: 140, fit: BoxFit.cover),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(movie.title, style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 8),
                          Text('Slug: ${movie.slug}'),
                          Text('Loại: ${movie.type} | Năm: ${movie.releaseYear ?? '-'}'),
                          Text('Quốc gia: ${movie.country ?? '-'} | Thời lượng: ${movie.duration ?? '-'} phút'),
                          const SizedBox(height: 8),
                          Text(movie.description ?? 'Không có mô tả.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (backdropUrl.isNotEmpty) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(backdropUrl, width: double.infinity, height: 200, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Danh sách tập phim', style: Theme.of(context).textTheme.titleLarge),
                FilledButton.icon(
                  onPressed: () => _openEpisodeForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm tập'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (_episodes.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Chưa có tập phim nào.')))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _episodes.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final ep = _episodes[index];
                  return ListTile(
                    leading: ep.thumbnailUrl != null
                        ? Image.network(UrlUtils.normalizeUrl(ep.thumbnailUrl), width: 80, height: 45, fit: BoxFit.cover)
                        : Container(width: 80, height: 45, color: Colors.grey[300], child: const Icon(Icons.movie)),
                    title: Text('S${ep.seasonNumber} E${ep.episodeNumber}: ${ep.title}'),
                    subtitle: Text(ep.videoUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(onPressed: () => _openEpisodeForm(ep), icon: const Icon(Icons.edit_outlined)),
                        IconButton(onPressed: () => _deleteEpisode(ep), icon: const Icon(Icons.delete_outline)),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _imagePreview({required String label, required String? url, required PickedUploadFile? file}) {
    Widget? image;
    if (file != null) {
      image = Image.memory(Uint8List.fromList(file.bytes), fit: BoxFit.cover);
    } else if (url != null && url.isNotEmpty) {
      image = Image.network(UrlUtils.normalizeUrl(url), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          height: 100, width: double.infinity,
          decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
          child: image != null ? ClipRRect(borderRadius: BorderRadius.circular(8), child: image) : const Icon(Icons.image, color: Colors.grey),
        ),
      ],
    );
  }
}
