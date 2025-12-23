class Song {
  final String name;
  final String album;
  final String url;
  final String albumImageUrl;

  Song({
    required this.name,
    required this.album,
    required this.url,
    required this.albumImageUrl,
  });

  /// 🔑 Unique key generated from existing fields
  String get uniqueKey => "$name|$album|$url";

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      name: json['name'],
      album: json['album'],
      url: json['url'],
      albumImageUrl: json['albumImageUrl'] ?? '',
    );
  }
}
