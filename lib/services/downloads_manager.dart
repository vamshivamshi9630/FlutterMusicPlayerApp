import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

/// Manages downloaded songs and persists them to SharedPreferences.
class DownloadsManager extends ChangeNotifier {
  static final DownloadsManager _instance = DownloadsManager._internal();
  factory DownloadsManager() => _instance;
  DownloadsManager._internal();

  final Map<String, Map<String, String>> _downloads = {}; // url -> {name, album, path, imageUrl}
  late SharedPreferences _prefs;
  static const String _downloadsKey = 'downloaded_songs';

  /// Initialize and load downloads from SharedPreferences
  Future<void> initialize() async {
    print('[DownloadsManager] initialize() start');
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadDownloads();
      print('[DownloadsManager] Loaded ${_downloads.length} downloads');
    } catch (e) {
      print('[DownloadsManager] initialize() error: $e');
    }
    print('[DownloadsManager] initialize() end');
  }

  /// Load downloads from SharedPreferences
  Future<void> _loadDownloads() async {
    final jsonList = _prefs.getStringList(_downloadsKey) ?? [];
    _downloads.clear();

    for (final json in jsonList) {
      try {
        final parts = json.split('|||');
        if (parts.length >= 5) {
          final url = parts[0];
          final name = parts[1];
          final album = parts[2];
          final path = parts[3];
          final imageUrl = parts[4];

          // Verify file still exists
          if (await File(path).exists()) {
            _downloads[url] = {
              'name': name,
              'album': album,
              'path': path,
              'imageUrl': imageUrl,
            };
          } else {
            // File was deleted, remove from list
            await _removeDownloadEntry(url);
          }
        }
      } catch (e) {
        print('Error loading download: $e');
      }
    }
    notifyListeners();
  }

  /// Add a downloaded song
  Future<void> addDownload(Song song, String localPath) async {
    _downloads[song.url] = {
      'name': song.name,
      'album': song.album,
      'path': localPath,
      'imageUrl': song.albumImageUrl,
    };
    await _saveDownloads();
    notifyListeners();
  }

  /// Check if a song is downloaded
  bool isDownloaded(String url) => _downloads.containsKey(url);

  /// Get the saved local path for a downloaded song
  String? getDownloadPath(String url) => _downloads[url]?['path'];

  /// Get all downloaded songs
  List<Song> getDownloadedSongs() {
    return _downloads.entries.map((entry) {
      final data = entry.value;
      return Song(
        url: entry.key,
        name: data['name'] ?? 'Unknown',
        album: data['album'] ?? 'Unknown',
        albumImageUrl: data['imageUrl'] ?? '',
      );
    }).toList();
  }

  /// Delete a downloaded song
  Future<void> deleteDownload(String url) async {
    final data = _downloads[url];
    if (data != null) {
      try {
        final file = File(data['path']!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error deleting file: $e');
      }
    }
    await _removeDownloadEntry(url);
    notifyListeners();
  }

  /// Remove download entry from preferences
  Future<void> _removeDownloadEntry(String url) async {
    _downloads.remove(url);
    await _saveDownloads();
  }

  /// Save downloads to SharedPreferences
  Future<void> _saveDownloads() async {
    final jsonList = _downloads.entries.map((entry) {
      final data = entry.value;
      return '${entry.key}|||${data['name']}|||${data['album']}|||${data['path']}|||${data['imageUrl']}';
    }).toList();
    await _prefs.setStringList(_downloadsKey, jsonList);
  }

  /// Clear all downloads
  Future<void> clearAll() async {
    for (final data in _downloads.values) {
      try {
        final file = File(data['path']!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error deleting file: $e');
      }
    }
    _downloads.clear();
    await _prefs.remove(_downloadsKey);
    notifyListeners();
  }
}
