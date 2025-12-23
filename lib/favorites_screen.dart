import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'models/song.dart';
import 'player_screen.dart';
import 'services/favorites_manager.dart';
import 'widgets/mini_player.dart';
import 'services/connectivity_service.dart';
// Auth/profile moved to WelcomeScreen
import 'screens/offline_screen.dart';

class FavoritesScreen extends StatelessWidget {
  FavoritesScreen({Key? key}) : super(key: key);

  final FavoritesManager favoritesManager = FavoritesManager();

  Widget _buildAlbumImage(String url) {
    if (url.isEmpty || !url.startsWith("http")) {
      return const Icon(Icons.album, size: 55, color: Colors.white);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 55,
        height: 55,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(width: 55, height: 55, color: const Color(0xFF1a1a1a)),
        errorWidget: (_, __, ___) => const Icon(Icons.album, size: 55, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ConnectivityService(),
      builder: (context, _) {
        // Show offline screen when no connectivity
        if (ConnectivityService().isOffline) {
          return const OfflineScreen(
            title: 'Favorites Not Available',
            message: 'You are offline. Browse your downloaded songs instead.',
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1a1a1a),
            elevation: 0,
            title: const Text(
              "Favorites",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            actions: [
              // Profile moved to WelcomeScreen

              // Clear-all favorites action
              AnimatedBuilder(
                animation: favoritesManager,
                builder: (context, _) {
                  final favs = favoritesManager.favoriteSongs;
                  if (favs.isNotEmpty) {
                    return IconButton(
                      icon: const Icon(Icons.delete_sweep, color: Colors.white70),
                      tooltip: 'Clear all favorites',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(0xFF282828),
                            title: const Text(
                              'Clear all favorites?',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: const Text(
                              'This will remove all songs from your favorites. This action cannot be undone.',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await favoritesManager.clearAll();
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('All favorites cleared'),
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
          body: Column(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: favoritesManager,
                  builder: (context, _) {
                    final List<Song> favoriteSongs =
                        favoritesManager.favoriteSongs;

                    if (favoriteSongs.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite_border,
                                size: 80, color: Colors.white30),
                            SizedBox(height: 20),
                            Text(
                              "No favorite songs yet",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: favoriteSongs.length,
                      itemBuilder: (context, index) {
                        final song = favoriteSongs[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF282828),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: _buildAlbumImage(song.albumImageUrl),
                            ),
                            title: Text(
                              song.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              song.album,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.favorite,
                                color: Color(0xFF1DB954),
                              ),
                              onPressed: () {
                                favoritesManager.toggleFavorite(song);
                              },
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PlayerScreen(
                                    albumSongs: favoriteSongs,
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
              ),
              MiniPlayer(),
            ],
          ),
        );
      },
    );
  }
}
