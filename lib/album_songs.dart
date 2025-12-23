import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:music_player/player_screen.dart';
import 'models/song.dart';
import 'widgets/mini_player.dart';
import 'services/connectivity_service.dart';

class AlbumSongsPage extends StatelessWidget {
  final String albumName;
  final List<Song> songs;

  const AlbumSongsPage({
    Key? key,
    required this.albumName,
    required this.songs,
  }) : super(key: key);

  Widget _buildSongImage(String url) {
    if (url.isEmpty || !url.startsWith("http")) {
      return const Icon(Icons.music_note, size: 50, color: Colors.white);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(width: 60, height: 60, color: const Color(0xFF1a1a1a)),
        errorWidget: (_, __, ___) => const Icon(Icons.music_note, size: 50, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final albumSongs =
    songs.where((song) => song.album == albumName).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          albumName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF1a1a1a),
        elevation: 0,
      ),
      body: Column(
        children: [
          AnimatedBuilder(
            animation: ConnectivityService(),
            builder: (context, _) {
              if (ConnectivityService().isOffline) {
                return Container(
                  width: double.infinity,
                  color: Color(0xFF2b2b2b),
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: const Text(
                    'Offline — streaming disabled',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: albumSongs.length,
              itemBuilder: (context, index) {
                final song = albumSongs[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Color(0xFF282828),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),

                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: _buildSongImage(song.albumImageUrl),
                    ),

                    title: Text(
                      song.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),

                    subtitle: Text(
                      song.album,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),

                    trailing: Icon(
                      Icons.play_arrow,
                      color: Color(0xFF1DB954),
                    ),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlayerScreen(
                            albumSongs: albumSongs,
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Mini Player at bottom
          MiniPlayer(),
        ],
      ),
    );
  }
}
