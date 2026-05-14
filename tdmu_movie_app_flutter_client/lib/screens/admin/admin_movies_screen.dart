import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../models/movie.dart';
import '../../models/admin_genre.dart';
import '../../services/admin_service.dart';
import '../../utils/upload_file_picker.dart';
import '../../utils/url_utils.dart';

import 'admin_movie_detail_screen.dart';

class AdminMoviesScreen extends StatefulWidget {
  const AdminMoviesScreen({super.key, required this.service});

  final AdminService service;

  @override
  State<AdminMoviesScreen> createState() => _AdminMoviesScreenState();
}

class _AdminMoviesScreenState extends State<AdminMoviesScreen> {
  bool _loading = true;
  List<Movie> _movies = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final movies = await widget.service.fetchMovies();
      if (!mounted) return;
      setState(() => _movies = movies);
    } on Exception catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openForm([Movie? movie]) async {
    final titleCtrl = TextEditingController(text: movie?.title ?? '');
    final slugCtrl = TextEditingController(text: movie?.slug ?? '');
    final descriptionCtrl = TextEditingController(
      text: movie?.description ?? '',
    );
    final posterCtrl = TextEditingController(text: movie?.posterUrl ?? '');
    final backdropCtrl = TextEditingController(text: movie?.backdropUrl ?? '');
    final releaseYearCtrl = TextEditingController(
      text: movie?.releaseYear?.toString() ?? '',
    );
    final countryCtrl = TextEditingController(text: movie?.country ?? '');
    final durationCtrl = TextEditingController(
      text: movie?.duration?.toString() ?? '',
    );
    PickedUploadFile? posterFile;
    PickedUploadFile? backdropFile;
    String type = movie?.type ?? 'single';
    bool isPublished = movie?.isPublished ?? true;
    final formKey = GlobalKey<FormState>();

    // Lấy danh sách thể loại
    List<AdminGenre> allGenres = [];
    List<int> selectedGenreIds = movie?.genres.map((g) => g.id).toList() ?? [];
    try {
      allGenres = await widget.service.fetchGenres();
    } catch (e) {
      debugPrint('Lỗi tải thể loại: $e');
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final screen = MediaQuery.of(context).size;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 980,
              maxHeight: screen.height * 0.9,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: StatefulBuilder(
                  builder: (context, setLocalState) {
                    Widget buildMainInfoSection() {
                      return _sectionCard(
                        context,
                        title: 'Thông tin chính',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: titleCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Tiêu đề',
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Bắt buộc'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: slugCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Slug',
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Bắt buộc'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: descriptionCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Mô tả',
                              ),
                              minLines: 3,
                              maxLines: 5,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: type,
                              items: const [
                                DropdownMenuItem(
                                  value: 'single',
                                  child: Text('single'),
                                ),
                                DropdownMenuItem(
                                  value: 'series',
                                  child: Text('series'),
                                ),
                              ],
                              onChanged: (value) =>
                                  setLocalState(() => type = value ?? 'single'),
                              decoration: const InputDecoration(
                                labelText: 'Loại',
                              ),
                            ),
                            const SizedBox(height: 6),
                            SwitchListTile(
                              value: isPublished,
                              onChanged: (value) =>
                                  setLocalState(() => isPublished = value),
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Hiển thị (published)'),
                            ),
                            const Divider(height: 24),
                            Text('Thể loại', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: allGenres.map((genre) {
                                final isSelected = selectedGenreIds.contains(genre.id);
                                return FilterChip(
                                  label: Text(genre.name, style: const TextStyle(fontSize: 12)),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setLocalState(() {
                                      if (selected) {
                                        selectedGenreIds.add(genre.id);
                                      } else {
                                        selectedGenreIds.remove(genre.id);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    }

                    Widget buildMediaSection() {
                      return _sectionCard(
                        context,
                        title: 'Ảnh & metadata',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _imagePreview(
                              label: 'Poster',
                              url: posterCtrl.text,
                              file: posterFile,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: posterCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Poster URL (tùy chọn)',
                              ),
                              onChanged: (_) => setLocalState(() {}),
                            ),
                            const SizedBox(height: 8),
                            _uploadRow(
                              context,
                              label: 'Upload poster',
                              fileName: posterFile?.name,
                              onTap: () async {
                                final result = await pickImageFile();
                                if (result == null) return;
                                setLocalState(() => posterFile = result);
                              },
                            ),
                            const Divider(height: 32),
                            _imagePreview(
                              label: 'Backdrop',
                              url: backdropCtrl.text,
                              file: backdropFile,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: backdropCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Backdrop URL (tùy chọn)',
                              ),
                              onChanged: (_) => setLocalState(() {}),
                            ),
                            const SizedBox(height: 8),
                            _uploadRow(
                              context,
                              label: 'Upload backdrop',
                              fileName: backdropFile?.name,
                              onTap: () async {
                                final result = await pickImageFile();
                                if (result == null) return;
                                setLocalState(() => backdropFile = result);
                              },
                            ),
                            const Divider(height: 32),
                            TextFormField(
                              controller: releaseYearCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Năm phát hành',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return null;
                                return int.tryParse(v.trim()) == null
                                    ? 'Năm phát hành không hợp lệ'
                                    : null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: countryCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Quốc gia',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: durationCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Thời lượng (phút)',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return null;
                                return int.tryParse(v.trim()) == null
                                    ? 'Thời lượng không hợp lệ'
                                    : null;
                              },
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                movie == null
                                    ? 'Tạo phim mới'
                                    : 'Cập nhật phim',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context, false),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ưu tiên upload file ảnh. URL vẫn giữ để tương thích dữ liệu cũ.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 820;
                              final content = isWide
                                  ? Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: buildMainInfoSection()),
                                        const SizedBox(width: 16),
                                        Expanded(child: buildMediaSection()),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        buildMainInfoSection(),
                                        const SizedBox(height: 12),
                                        buildMediaSection(),
                                      ],
                                    );

                              return SingleChildScrollView(child: content);
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Hủy'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () {
                                if (formKey.currentState!.validate()) {
                                  Navigator.pop(context, true);
                                }
                              },
                              child: const Text('Lưu phim'),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    final payload = <String, dynamic>{
      'title': titleCtrl.text.trim(),
      'slug': slugCtrl.text.trim(),
      'description': _nullableText(descriptionCtrl.text),
      'poster_url': _nullableText(posterCtrl.text),
      'backdrop_url': _nullableText(backdropCtrl.text),
      'release_year': _nullableInt(releaseYearCtrl.text),
      'country': _nullableText(countryCtrl.text),
      'duration': _nullableInt(durationCtrl.text),
      'type': type,
      'is_published': isPublished,
      'genres': selectedGenreIds,
    };
    if (posterFile != null) {
      payload['poster_file'] = posterFile!;
    }
    if (backdropFile != null) {
      payload['backdrop_file'] = backdropFile!;
    }

    try {
      if (movie == null) {
        await widget.service.createMovie(payload);
      } else {
        await widget.service.updateMovie(movie.id, payload);
      }
      await _load();
    } on Exception catch (e) {
      _showMessage(e.toString());
    }
  }

  Future<void> _delete(Movie movie) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa phim'),
        content: Text('Bạn có chắc muốn xóa "${movie.title}"?'),
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
      await widget.service.deleteMovie(movie.id);
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

  Future<void> _openDetail(Movie movie) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminMovieDetailScreen(movie: movie, service: widget.service),
      ),
    );
    _load(); // Refresh movies if needed (e.g. if movie info could change there, though currently it doesn't)
  }


  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _imagePreview({
    required String label,
    required String? url,
    required PickedUploadFile? file,
  }) {
    Widget? image;
    if (file != null) {
      image = Image.memory(Uint8List.fromList(file.bytes), fit: BoxFit.cover);
    } else if (url != null && url.isNotEmpty) {
      image = Image.network(
        UrlUtils.normalizeUrl(url),
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
          height: 120,
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

  Widget _uploadRow(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
    required String? fileName,
  }) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.upload_file),
          label: Text(label),
        ),
        if (fileName != null)
          Text(fileName, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  String? _nullableText(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  int? _nullableInt(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return int.tryParse(normalized);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRUD phim'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: () => _openForm(), icon: const Icon(Icons.add)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: _movies.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final movie = _movies[index];
                final posterUrl = UrlUtils.normalizeUrl(movie.posterUrl);

                return ListTile(
                  onTap: () => _openDetail(movie),
                  leading: Container(
                    width: 48,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: posterUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              posterUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.broken_image, size: 20),
                            ),
                          )
                        : const Icon(Icons.movie, color: Colors.grey),
                  ),
                  title: Text(movie.title),
                  subtitle: Text('slug: ${movie.slug} | ${movie.type}'),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        onPressed: () => _openForm(movie),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () => _delete(movie),
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
