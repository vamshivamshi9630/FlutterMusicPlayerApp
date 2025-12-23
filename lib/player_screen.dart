import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'models/song.dart';
import 'services/favorites_manager.dart';
import 'services/audio_service.dart';
import 'services/connectivity_service.dart';
import 'services/downloads_manager.dart';

class PlayerScreen extends StatefulWidget {
  final List<Song> albumSongs;
  final int initialIndex;

  const PlayerScreen({
    super.key,
    required this.albumSongs,
    required this.initialIndex,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final AudioService audioService = AudioService();
  final FavoritesManager favoritesManager = FavoritesManager();
  bool _isDownloading = false;
  final DownloadsManager _downloadsManager = DownloadsManager();

  @override
  void initState() {
    super.initState();

    audioService.playSong(
      widget.albumSongs[widget.initialIndex],
      widget.albumSongs,
      widget.initialIndex,
    ).catchError((e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Playback failed: ${e.toString()}')),
        );
      });
    });

    audioService.addListener(_onAudioServiceChanged);
  }

  void _onAudioServiceChanged() => setState(() {});

  @override
  void dispose() {
    audioService.removeListener(_onAudioServiceChanged);
    super.dispose();
  }

  double _getSliderValue() {
    final positionSeconds = audioService.position.inSeconds.toDouble();
    final maxSeconds = audioService.duration.inSeconds.toDouble();
    if (maxSeconds <= 0) return 0;
    return positionSeconds.clamp(0.0, maxSeconds);
  }

  double _getMaxSliderValue() {
    final durationSeconds = audioService.duration.inSeconds.toDouble();
    return durationSeconds > 0 ? durationSeconds : 1.0;
  }

  Widget _buildAlbumImage(String url) {
    if (url.isEmpty || !url.startsWith('http')) {
      return const Icon(Icons.album, size: 200, color: Colors.white);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 250,
        height: 250,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: 250,
          height: 250,
          color: const Color(0xFF1a1a1a),
        ),
        errorWidget: (_, __, ___) => const Icon(Icons.album, size: 200, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = audioService.currentSong;
    if (currentSong == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1a1a1a),
          title: const Text('Player'),
        ),
        body: const Center(child: Text('No song selected')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a1a),
        elevation: 0,
        title: const Text(
          'Now Playing',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          AnimatedBuilder(
            animation: favoritesManager,
            builder: (_, __) {
              final fav = favoritesManager.isFavorite(currentSong);
              return IconButton(
                icon: Icon(
                  fav ? Icons.favorite : Icons.favorite_border,
                  color: fav ? const Color(0xFF1DB954) : Colors.white,
                ),
                onPressed: () => favoritesManager.toggleFavorite(currentSong),
              );
            },
          ),
          AnimatedBuilder(
            animation: _downloadsManager,
            builder: (_, __) {
              final already = _downloadsManager.isDownloaded(currentSong.url);
              return IconButton(
                icon: _isDownloading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
                        ),
                      )
                    : Icon(already ? Icons.download_done : Icons.download_rounded, color: Colors.white),
                onPressed: (_isDownloading || already)
                    ? null
                    : () async {
                        setState(() => _isDownloading = true);
                        try {
                          if (_downloadsManager.isDownloaded(currentSong.url)) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Track already downloaded')));
                            }
                            return;
                          }
                          await audioService.downloadSong(currentSong);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Track downloaded successfully!'), duration: Duration(seconds: 2)));
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: ${e.toString()}'), duration: const Duration(seconds: 3)));
                          }
                        } finally {
                          if (mounted) setState(() => _isDownloading = false);
                        }
                      },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            AnimatedBuilder(
              animation: ConnectivityService(),
              builder: (context, _) {
                if (ConnectivityService().isOffline) {
                  return Container(
                    width: double.infinity,
                    color: const Color(0xFF2b2b2b),
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    child: const Text(
                      'Offline — using downloaded tracks only',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1DB954).withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(child: _buildAlbumImage(currentSong.albumImageUrl)),
                    ),

                    const SizedBox(height: 40),

                    Text(
                      currentSong.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      currentSong.album,
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Slider(
                    activeColor: const Color(0xFF1DB954),
                    inactiveColor: const Color(0xFF404040),
                    value: _getSliderValue(),
                    min: 0,
                    max: _getMaxSliderValue(),
                    onChanged: (v) => audioService.seek(Duration(seconds: v.toInt())),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${audioService.position.inMinutes}:${(audioService.position.inSeconds % 60).toString().padLeft(2, '0')}",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        "${audioService.duration.inMinutes}:${(audioService.duration.inSeconds % 60).toString().padLeft(2, '0')}",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Controls (lifted above bottom by SafeArea + SizedBox)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(Icons.shuffle, color: audioService.isShuffle ? const Color(0xFF1DB954) : Colors.white54, size: 28),
                        onPressed: () => audioService.toggleShuffle(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
                        onPressed: () => audioService.playPrevious(),
                      ),
                      Container(
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1DB954)),
                        child: IconButton(
                          icon: Icon(audioService.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.black, size: 36),
                          iconSize: 56,
                          onPressed: () => audioService.togglePlayPause(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
                        onPressed: () => audioService.playNext(),
                      ),
                      IconButton(
                        icon: Icon(Icons.repeat, color: audioService.isRepeat ? const Color(0xFF1DB954) : Colors.white54, size: 28),
                        onPressed: () => audioService.toggleRepeat(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}
