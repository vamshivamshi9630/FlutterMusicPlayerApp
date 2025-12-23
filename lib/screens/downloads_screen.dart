import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/downloads_manager.dart';
import '../services/audio_service.dart';
import '../player_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({Key? key}) : super(key: key);

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final DownloadsManager _downloadsManager = DownloadsManager();
  final AudioService _audioService = AudioService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a1a),
        elevation: 0,
        title: const Text(
          'Downloaded Songs',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          AnimatedBuilder(
            animation: _downloadsManager,
            builder: (context, _) {
              final downloads = _downloadsManager.getDownloadedSongs();
              if (downloads.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_sweep, color: Colors.white70),
                  tooltip: 'Clear all downloads',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF282828),
                        title: const Text(
                          'Clear all downloads?',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: const Text(
                          'This will delete all downloaded songs. This action cannot be undone.',
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              _downloadsManager.clearAll();
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('All downloads cleared'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _downloadsManager,
        builder: (context, _) {
          final downloads = _downloadsManager.getDownloadedSongs();

          if (downloads.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF282828),
                      ),
                      child: const Icon(
                        Icons.download_rounded,
                        size: 64,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No downloads yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Download songs while connected to listen offline',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Go Back'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DB954),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: downloads.length,
            itemBuilder: (context, index) {
              final song = downloads[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF282828),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: song.albumImageUrl.isNotEmpty &&
                            song.albumImageUrl.startsWith("http")
                        ? CachedNetworkImage(
                            imageUrl: song.albumImageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              width: 50,
                              height: 50,
                              color: const Color(0xFF1a1a1a),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 50,
                              height: 50,
                              color: const Color(0xFF1a1a1a),
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.white54,
                              ),
                            ),
                          )
                        : Container(
                            width: 50,
                            height: 50,
                            color: const Color(0xFF1a1a1a),
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.white54,
                            ),
                          ),
                  ),
                  title: Text(
                    song.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    song.album,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: PopupMenuButton<String>(
                    color: const Color(0xFF282828),
                    onSelected: (value) async {
                      if (value == 'play') {
                        _audioService.playSong(song, downloads, index);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => PlayerScreen(
                              albumSongs: downloads,
                              initialIndex: index,
                            ),
                          ),
                        );
                      } else if (value == 'delete') {
                        await _downloadsManager.deleteDownload(song.url);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✓ Download deleted'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'play',
                        child: Row(
                          children: [
                            Icon(Icons.play_arrow, color: Color(0xFF1DB954)),
                            SizedBox(width: 8),
                            Text('Play', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    _audioService.playSong(song, downloads, index);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => PlayerScreen(
                          albumSongs: downloads,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
