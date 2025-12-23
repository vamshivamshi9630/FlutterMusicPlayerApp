import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'album_songs.dart';
import 'models/song.dart';
import 'services/song_service.dart';
import 'widgets/mini_player.dart';
import 'services/connectivity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/offline_screen.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  late Future<List<Song>> songsFuture;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  List<String> _searchHistory = [];
  static const String _kSearchHistoryKey = 'album_search_history';

  @override
  void initState() {
    super.initState();
    songsFuture = fetchSongs();
    _loadSearchHistory();
  }
  @override
  void dispose() {

    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kSearchHistoryKey) ?? <String>[];
      setState(() => _searchHistory = List<String>.from(list));
    } catch (_) {
      // ignore
    }
  }

  Future<void> _addToSearchHistory(String q) async {
    final normalized = q.trim();
    if (normalized.isEmpty) return;
    // keep recent first, unique
    _searchHistory.removeWhere((e) => e.toLowerCase() == normalized.toLowerCase());
    _searchHistory.insert(0, normalized);
    if (_searchHistory.length > 10) _searchHistory = _searchHistory.sublist(0, 10);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kSearchHistoryKey, _searchHistory);
    } catch (_) {}
    setState(() {});
  }
  Widget _buildAlbumImage(String url) {
    if (url.isEmpty || !url.startsWith("http")) {
      return const Icon(Icons.album, size: 55, color: Colors.white);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(width: 60, height: 60, color: const Color(0xFF1a1a1a)),
        errorWidget: (_, __, ___) => const Icon(Icons.album, size: 55, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ConnectivityService(),
      builder: (context, _) {
        if (ConnectivityService().isOffline) {
          return const OfflineScreen(
            title: 'Albums Not Available',
            message: 'You are offline. Browse your downloaded songs instead.',
          );
        }

        return PopScope(
          canPop: _searchController.text.isEmpty,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              setState(() {
                _searchController.clear();
                searchQuery = '';
              });
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFF121212),
            appBar: AppBar(
              backgroundColor: const Color(0xFF1a1a1a),
              title: Row(
                children: [
                  const Text(
                    'Albums',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search albums...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          prefixIcon: const Icon(Icons.search, color: Colors.white70),
                          suffixIcon: _searchHistory.isEmpty
                              ? null
                              : PopupMenuButton<String>(
                                  icon: const Icon(Icons.history, color: Colors.white70),
                                  onSelected: (v) {
                                    _searchController.text = v;
                                    setState(() => searchQuery = v.toLowerCase());
                                  },
                                  itemBuilder: (ctx) => _searchHistory
                                      .map((s) => PopupMenuItem(value: s, child: Text(s)))
                                      .toList(),
                                ),
                          filled: true,
                          fillColor: const Color(0xFF282828),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
                        onSubmitted: (v) async {
                          await _addToSearchHistory(v);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              elevation: 0,
            ),
            body: Column(
              children: [
                const SizedBox(height: 12),
                Expanded(
                  child: FutureBuilder<List<Song>>(
                    future: songsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Error loading albums', style: TextStyle(color: Colors.red)),
                        );
                      }

                      final songs = snapshot.data!;
                      final albums = songs.map((s) => s.album).toSet().where((a) => a.toLowerCase().contains(searchQuery));

                      return ListView(
                        padding: const EdgeInsets.all(12),
                        children: albums.map((album) {
                          final albumSong = songs.firstWhere((s) => s.album == album);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF282828),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: _buildAlbumImage(albumSong.albumImageUrl),
                              title: Text(
                                album,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.play_circle,
                                color: Color(0xFF1DB954),
                                size: 28,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AlbumSongsPage(albumName: album, songs: songs),
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
                MiniPlayer(),
              ],
            ),
          ),
        );
      },
    );
  }
}
