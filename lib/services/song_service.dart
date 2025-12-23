import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';

Future<List<Song>> fetchSongs() async {
  const String url =
      "https://raw.githubusercontent.com/vamshivamshi9630/MusicData/refs/heads/main/songs.json";

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    List decoded = json.decode(response.body);
    return decoded.map((e) => Song.fromJson(e)).toList();
  } else {
    throw Exception("Failed to load songs");
  }
}
