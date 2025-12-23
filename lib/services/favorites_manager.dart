import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import 'auth_service.dart';
import 'cloud_sync_service.dart';

class FavoritesManager extends ChangeNotifier {
  // 🔹 Singleton
  static final FavoritesManager _instance =
  FavoritesManager._internal();
  factory FavoritesManager() => _instance;
  FavoritesManager._internal();

  static const String _prefsKey = 'favorite_song_urls';

  final Map<String, Song> _favorites = {};
  bool _initialized = false;
  final AuthService _authService = AuthService();
  final CloudSyncService _cloudSyncService = CloudSyncService();

  /// 🔹 Load favorites ONCE from SharedPreferences
  Future<void> loadFavorites(List<Song> allSongs) async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final savedUrls = prefs.getStringList(_prefsKey) ?? [];

    for (final url in savedUrls) {
      try {
        final song = allSongs.firstWhere((s) => s.url == url);
        _favorites[url] = song;
      } catch (_) {}
    }

    _initialized = true;
    notifyListeners();
  }

  bool isFavorite(Song song) => _favorites.containsKey(song.url);

  List<Song> get favoriteSongs => _favorites.values.toList();

  /// Add favorite and sync to cloud if logged in
  Future<void> addFavorite(Song song) async {
    if (isFavorite(song)) return;
    
    final prefs = await SharedPreferences.getInstance();
    _favorites[song.url] = song;
    
    await prefs.setStringList(
      _prefsKey,
      _favorites.keys.toList(),
    );

    notifyListeners();
    
    // Sync to cloud if logged in
    if (_authService.isLoggedIn) {
      print('[FavoritesManager] Syncing favorite to cloud: ${song.name}');
      await _cloudSyncService.uploadFavorites(favoriteSongs);
    }
  }

  /// Remove favorite and sync to cloud if logged in
  Future<void> removeFavorite(Song song) async {
    if (!isFavorite(song)) return;
    
    final prefs = await SharedPreferences.getInstance();
    _favorites.remove(song.url);
    
    await prefs.setStringList(
      _prefsKey,
      _favorites.keys.toList(),
    );

    notifyListeners();
    
    // Sync to cloud if logged in
    if (_authService.isLoggedIn) {
      print('[FavoritesManager] Syncing favorites to cloud after removal');
      await _cloudSyncService.uploadFavorites(favoriteSongs);
    }
  }

  /// Toggle favorite and sync
  Future<void> toggleFavorite(Song song) async {
    final prefs = await SharedPreferences.getInstance();

    if (isFavorite(song)) {
      _favorites.remove(song.url);
    } else {
      _favorites[song.url] = song;
    }

    await prefs.setStringList(
      _prefsKey,
      _favorites.keys.toList(),
    );

    notifyListeners();
    
    // Sync to cloud if logged in
    if (_authService.isLoggedIn) {
      print('[FavoritesManager] Syncing favorites to cloud after toggle');
      await _cloudSyncService.uploadFavorites(favoriteSongs);
    }
  }

  /// Clear all favorites and sync to cloud if logged in
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    _favorites.clear();

    await prefs.setStringList(_prefsKey, []);

    notifyListeners();

    if (_authService.isLoggedIn) {
      print('[FavoritesManager] Clearing all favorites and syncing to cloud');
      await _cloudSyncService.uploadFavorites(favoriteSongs);
    }
  }
}
