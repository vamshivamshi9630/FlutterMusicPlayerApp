import 'package:flutter/material.dart';
import '../models/song.dart';
import 'auth_service.dart';

class CloudSyncService extends ChangeNotifier {
  // 🔹 Singleton
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  bool _isSyncing = false;
  bool _initialized = false;

  bool get isSyncing => _isSyncing;

  /// Initialize cloud sync (local-only mode, Firebase unavailable)
  Future<void> initialize() async {
    if (_initialized) return;
    print('[CloudSyncService] initialize() start (local-only mode)');
    _initialized = true;
    print('[CloudSyncService] Cloud sync disabled - running in local-only mode');
    notifyListeners();
    print('[CloudSyncService] initialize() end');
  }

  /// Disable sync (called when user logs out)
  Future<void> disable() async {
    print('[CloudSyncService] Cloud sync disabled');
    notifyListeners();
  }

  /// Upload favorites (local-only, Firestore unavailable)
  Future<bool> uploadFavorites(List<Song> favorites) async {
    try {
      _isSyncing = true;
      notifyListeners();

      print('[CloudSyncService] Saving ${favorites.length} favorites locally (cloud sync unavailable)');
      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('[CloudSyncService] ✗ Error saving favorites: $e');
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Download favorites (local-only, Firestore unavailable)
  Future<List<Song>> downloadFavorites() async {
    print('[CloudSyncService] Cloud sync unavailable - using local favorites');
    return [];
  }

}
