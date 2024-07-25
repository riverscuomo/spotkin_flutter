class DisplayItem {
  final String id;
  final String name;
  final String type;
  final String? imageUrl;
  final String? subtitle;

  DisplayItem({
    required this.id,
    required this.name,
    required this.type,
    this.imageUrl,
    this.subtitle,
  });
}
