import 'package:flutter/material.dart';

import '../../models/admin_genre.dart';
import '../../services/admin_service.dart';

class AdminGenresScreen extends StatefulWidget {
  const AdminGenresScreen({super.key, required this.service});

  final AdminService service;

  @override
  State<AdminGenresScreen> createState() => _AdminGenresScreenState();
}

class _AdminGenresScreenState extends State<AdminGenresScreen> {
  bool _loading = true;
  List<AdminGenre> _genres = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final genres = await widget.service.fetchGenres();
      if (!mounted) return;
      setState(() => _genres = genres);
    } on Exception catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openForm([AdminGenre? genre]) async {
    final nameCtrl = TextEditingController(text: genre?.name ?? '');
    final slugCtrl = TextEditingController(text: genre?.slug ?? '');
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(genre == null ? 'Tạo thể loại' : 'Cập nhật thể loại'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Tên'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
                ),
                TextFormField(
                  controller: slugCtrl,
                  decoration: const InputDecoration(labelText: 'Slug'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
                ),
              ],
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

    final payload = {
      'name': nameCtrl.text.trim(),
      'slug': slugCtrl.text.trim(),
    };
    try {
      if (genre == null) {
        await widget.service.createGenre(payload);
      } else {
        await widget.service.updateGenre(genre.id, payload);
      }
      await _load();
    } on Exception catch (e) {
      _showMessage(e.toString());
    }
  }

  Future<void> _delete(AdminGenre genre) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa thể loại'),
        content: Text('Bạn có chắc muốn xóa "${genre.name}"?'),
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
      await widget.service.deleteGenre(genre.id);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRUD thể loại'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: () => _openForm(), icon: const Icon(Icons.add)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: _genres.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final genre = _genres[index];
                return ListTile(
                  title: Text(genre.name),
                  subtitle: Text('slug: ${genre.slug}'),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        onPressed: () => _openForm(genre),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () => _delete(genre),
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
