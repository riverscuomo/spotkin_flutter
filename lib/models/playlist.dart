class MyPlaylist {
  final String id;
  final String link;
  final String name;

  MyPlaylist({required this.id, required this.link, required this.name});

  factory MyPlaylist.fromJson(Map<String, dynamic> json) {
    return MyPlaylist(id: json['id'], link: json['link'], name: json['name']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id,
    'link': link,
     'name': name};
  }
}
