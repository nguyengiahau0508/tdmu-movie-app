class AdminGenre {
  const AdminGenre({required this.id, required this.name, required this.slug});

  final int id;
  final String name;
  final String slug;

  factory AdminGenre.fromJson(Map<String, dynamic> json) {
    return AdminGenre(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String?) ?? '',
      slug: (json['slug'] as String?) ?? '',
    );
  }
}
