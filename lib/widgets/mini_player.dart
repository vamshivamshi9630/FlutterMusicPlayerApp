import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../player_screen.dart';
import '../services/audio_service.dart';

class MiniPlayer extends StatelessWidget {
  final AudioService audioService = AudioService();

  MiniPlayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: audioService,
      builder: (context, _) {
        final currentSong = audioService.currentSong;

        // Don't show mini player if no song is playing
        if (currentSong == null) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            // Open full player screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlayerScreen(
                  albumSongs: audioService.currentPlaylist ?? [],
                  initialIndex: audioService.currentPlaylistIndex,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFF282828),
              border: Border(
                top: BorderSide(
                  color: Color(0xFF404040),
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Album Art
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: currentSong.albumImageUrl.isNotEmpty &&
                      currentSong.albumImageUrl.startsWith("http")
                      ? CachedNetworkImage(
                    imageUrl: currentSong.albumImageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(width: 50, height: 50, color: const Color(0xFF1a1a1a)),
                    errorWidget: (_, __, ___) => Container(
                      width: 50,
                      height: 50,
                      color: const Color(0xFF1a1a1a),
                      child: const Icon(
                        Icons.album,
                        size: 28,
                        color: Colors.white54,
                      ),
                    ),
                  )
                      : Container(
                    width: 50,
                    height: 50,
                    color: const Color(0xFF1a1a1a),
                    child: const Icon(
                      Icons.album,
                      size: 28,
                      color: Colors.white54,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Song Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currentSong.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentSong.album,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Play/Pause Button
                GestureDetector(
                  onTap: () => audioService.togglePlayPause(),
                  child: Icon(
                    audioService.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Color(0xFF1DB954),
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
