import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/song.dart';
import 'connectivity_service.dart';
import 'downloads_manager.dart';

class AudioService extends ChangeNotifier {
  // 🔹 Singleton - Global audio player
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  late AudioPlayer _audioPlayer;
  final Map<String, String> _localCache = {}; // map song.url -> local file path
  
  // Global state - tracks which song is currently playing globally
  Song? _currentSong;
  bool _isPlaying = false;
  bool _isRepeat = false;
  bool _isShuffle = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  List<Song>? _currentPlaylist;
  int _currentPlaylistIndex = -1;

  // Getters for global state
  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  bool get isRepeat => _isRepeat;
  bool get isShuffle => _isShuffle;
  Duration get duration => _duration;
  Duration get position => _position;
  List<Song>? get currentPlaylist => _currentPlaylist;
  int get currentPlaylistIndex => _currentPlaylistIndex;

  /// Initialize AudioService (call once in main.dart)
  Future<void> initialize() async {
    print('[AudioService] initialize() start');
    try {
      _audioPlayer = AudioPlayer();
      _setupAudioListeners();
      print('[AudioService] AudioPlayer created and listeners attached');
    } catch (e) {
      print('[AudioService] initialize() error: $e');
    }
    print('[AudioService] initialize() end');
  }

  void _setupAudioListeners() {
    _audioPlayer.onDurationChanged.listen((d) {
      _duration = d;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((p) {
      // Clamp position to not exceed duration
      if (_duration.inMilliseconds > 0 && p.inMilliseconds > _duration.inMilliseconds) {
        _position = _duration;
      } else {
        _position = p;
      }
      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (_isRepeat && _currentPlaylist != null) {
        _playSong(_currentPlaylistIndex);
      } else if (_currentPlaylist != null) {
        _playNextInPlaylist();
      }
    });
  }

  /// Play a song from a playlist
  Future<void> playSong(Song song, List<Song> playlist, int index) async {
    _currentSong = song;
    _currentPlaylist = playlist;
    _currentPlaylistIndex = index;
    _position = Duration.zero; // Reset position to start of new song

    await playUrlOrLocal(song);
    _isPlaying = true;
    notifyListeners();
  }

  /// Load a playlist without playing (just update context)
  void loadPlaylist(List<Song> songs, int index) {
    _currentPlaylist = songs;
    _currentPlaylistIndex = index;
    notifyListeners();
  }

  /// Internal method to play song by index
  Future<void> _playSong(int index) async {
    if (_currentPlaylist == null || index < 0 || index >= _currentPlaylist!.length) return;

    _currentPlaylistIndex = index;
    _currentSong = _currentPlaylist![index];
    _position = Duration.zero; // Reset position when playing next song

    // Skip stop() when auto-playing next song - just play directly for faster transition
    try {
      await playUrlOrLocal(_currentSong!);
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      // If there's an error, try stop + stream as fallback
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(_currentSong!.url));
      _isPlaying = true;
      notifyListeners();
    }
  }

  /// Try to play a locally downloaded file if available; otherwise stream.
  Future<void> playUrlOrLocal(Song song) async {
    final connectivity = ConnectivityService();
    final localPath = await _localPathForSong(song);

    if (localPath != null && await File(localPath).exists()) {
      await _audioPlayer.play(DeviceFileSource(localPath));
      return;
    }

    // If offline and not downloaded, throw so UI can handle it
    if (connectivity.isOffline) {
      throw Exception('Offline and track not downloaded');
    }

    // Otherwise stream
    await _audioPlayer.play(UrlSource(song.url));
  }

  /// Download a song to local storage and return the saved file path.
  Future<String> downloadSong(Song song) async {
    try {
      // If already downloaded, return existing path
      final existingPath = DownloadsManager().getDownloadPath(song.url);
      if (existingPath != null) {
        print('[AudioService] downloadSong: already downloaded at $existingPath');
        return existingPath;
      }

      // If cached local path exists and file is present, return it
      final cached = _localCache[song.url];
      if (cached != null && await File(cached).exists()) {
        print('[AudioService] downloadSong: local cache hit at $cached');
        return cached;
      }

      print('[AudioService] ========== DOWNLOAD START ==========');
      print('[AudioService] Song: ${song.name}');
      print('[AudioService] URL: ${song.url}');
      final uri = Uri.parse(song.url);
      print('[AudioService] Fetching audio data (5min timeout)...');
      final response = await http.get(uri).timeout(const Duration(minutes: 5));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: Failed to download audio');
      }
      print('[AudioService] ✓ HTTP response: ${response.statusCode}, Received ${response.bodyBytes.length} bytes');
      final bytes = response.bodyBytes;
      
      print('[AudioService] Computing local storage path with createIfMissing=true...');
      final path = await _localPathForSong(song, createIfMissing: true);
      if (path == null) throw Exception('Unable to determine local storage path');
      print('[AudioService] ✓ Path: $path');
      
      try {
        final file = File(path);
        print('[AudioService] File object created: ${file.path}');
        print('[AudioService] Writing ${bytes.length} bytes to disk...');
        // Write to a temporary file first to avoid partial-write races
        final tmpPath = '$path.tmp.${DateTime.now().millisecondsSinceEpoch}';
        final tmpFile = File(tmpPath);
        await tmpFile.writeAsBytes(bytes);
        // Move into place
        try {
          await tmpFile.rename(path);
        } catch (e) {
          // If rename fails, try to copy and delete tmp
          print('[AudioService] rename failed, attempting copy: $e');
          await tmpFile.copy(path);
          try {
            await tmpFile.delete();
          } catch (_) {}
        }
        print('[AudioService] ✓ File written successfully');
        _localCache[song.url] = path;
        
        // Track download in DownloadsManager
        print('[AudioService] Registering download in DownloadsManager...');
        await DownloadsManager().addDownload(song, path);
        print('[AudioService] ✓ Download registered successfully');
        print('[AudioService] ========== DOWNLOAD SUCCESS ==========');
        
        return path;
      } catch (e) {
        print('[AudioService] ✗ File write error: $e');
        print('[AudioService] Error type: ${e.runtimeType}');
        throw Exception('Failed to save file: ${e.toString()}');
      }
    } catch (e) {
      print('[AudioService] ✗ Download error: $e');
      print('[AudioService] ========== DOWNLOAD FAILED ==========');
      throw Exception('Download failed: ${e.toString()}');
    }
  }

  /// Compute a reasonable local path for a song. If createIfMissing is true,
  /// ensure parent directory exists.
  Future<String?> _localPathForSong(Song song, {bool createIfMissing = false}) async {
    try {
      print('[AudioService] [_localPathForSong] Starting with createIfMissing=$createIfMissing');
      // Try getTemporaryDirectory first, fallback to getApplicationDocumentsDirectory
      Directory dir;
      try {
        dir = await getTemporaryDirectory();
        print('[AudioService] Using temp directory: ${dir.path}');
      } catch (e) {
        print('[AudioService] Temp directory failed, using documents: $e');
        dir = await getApplicationDocumentsDirectory();
        print('[AudioService] Using documents directory: ${dir.path}');
      }

      // Create a safe filename from the URL or song name
      final fileName = Uri.parse(song.url).pathSegments.isNotEmpty
          ? Uri.parse(song.url).pathSegments.last
          : '${song.name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')}.mp3';
      
      // Remove query parameters and make filename safe
      final safeName = fileName.split('?').first.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      
      // Create offline_tracks directory with proper path joining
      final folder = Directory(path.join(dir.path, 'offline_tracks'));
      print('[AudioService] Target folder: ${folder.path}');
      
      // ALWAYS create directory if createIfMissing is true, regardless of cache
      if (createIfMissing) {
        print('[AudioService] createIfMissing is TRUE, ensuring directory exists...');
        final exists = await folder.exists();
        print('[AudioService] Directory exists: $exists');
        
        if (!exists) {
          print('[AudioService] Creating directory: ${folder.path}');
          try {
            await folder.create(recursive: true);
            print('[AudioService] ✓ Directory created successfully');
          } catch (createError) {
            print('[AudioService] ✗ Failed to create directory: $createError');
            rethrow;
          }
        } else {
          print('[AudioService] Directory already exists, skipping creation');
        }
      } else {
        print('[AudioService] createIfMissing is FALSE, skipping directory creation');
      }

      final fullPath = path.join(folder.path, safeName);
      print('[AudioService] Full file path: $fullPath');
      // Cache it for future use
      _localCache[song.url] = fullPath;
      return fullPath;
    } catch (e) {
      print('[AudioService] Error computing local path: $e');
      return null;
    }
  }

  /// Play the current song
  Future<void> play() async {
    if (_currentSong == null) return;

    if (_isPlaying) return;

    try {
      // Try to resume if possible, otherwise attempt to (re)load the source
      await _audioPlayer.resume();
      _isPlaying = true;
      notifyListeners();
    } catch (_) {
      // If resume fails (e.g., no streaming while offline), attempt to play local or stream
      try {
        await playUrlOrLocal(_currentSong!);
        _isPlaying = true;
        notifyListeners();
      } catch (e) {
        rethrow;
      }
    }
  }

  /// Pause the current song
  Future<void> pause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      _isPlaying = false;
      notifyListeners();
    }
  }

  /// Toggle play/pause
  void togglePlayPause() {
    _isPlaying ? pause() : play();
  }

  /// Play next song in current playlist
  Future<void> playNext() async {
    if (_currentPlaylist == null) return;
    _currentPlaylistIndex = (_currentPlaylistIndex + 1) % _currentPlaylist!.length;
    await _playSong(_currentPlaylistIndex);
  }

  Future<void> _playNextInPlaylist() async {
    if (_currentPlaylist == null) return;
    _currentPlaylistIndex = (_currentPlaylistIndex + 1) % _currentPlaylist!.length;
    await _playSong(_currentPlaylistIndex);
  }

  /// Play previous song in current playlist
  Future<void> playPrevious() async {
    if (_currentPlaylist == null) return;
    _currentPlaylistIndex = (_currentPlaylistIndex - 1 + _currentPlaylist!.length) % _currentPlaylist!.length;
    await _playSong(_currentPlaylistIndex);
  }

  /// Toggle repeat mode
  void toggleRepeat() {
    _isRepeat = !_isRepeat;
    notifyListeners();
  }

  /// Toggle shuffle mode
  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  /// Dispose (call in app cleanup)
  void disposeAudio() {
    _audioPlayer.dispose();
  }
}
