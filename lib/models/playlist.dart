class Playlist {
  final String id;
  final String link;
  final String name;

  Playlist({required this.id, required this.link, required this.name});

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(id: json['id'], link: json['link'], name: json['name']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id,
    'link': link,
     'name': name};
  }
}
