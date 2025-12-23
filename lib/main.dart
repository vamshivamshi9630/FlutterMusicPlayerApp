import 'package:flutter/material.dart';
import 'services/favorites_manager.dart';
import 'services/song_service.dart';
import 'services/audio_service.dart';
import 'services/connectivity_service.dart';
import 'services/downloads_manager.dart';
import 'services/auth_service.dart';
import 'services/cloud_sync_service.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Start initialization asynchronously so the UI can show immediately.
  final Future<void> initialization = _initializeApp();

  runApp(MyApp(initialization: initialization));
}

/// Performs app-wide initialization without blocking the UI.
Future<void> _initializeApp() async {
  // Firebase disabled - Windows uses guest mode only
  // For future Android/iOS Firebase support:
  // if (!Platform.isWindows) {
  //   try {
  //     await Firebase.initializeApp(
  //       options: DefaultFirebaseOptions.currentPlatform,
  //     );
  //     print('[main] Firebase initialized successfully');
  //   } catch (e) {
  //     print('[main] Firebase initialization failed: $e');
  //   }
  // } else {
  //   print('[main] Windows detected - skipping Firebase, using guest mode');
  // }
  print('[main] Firebase disabled - all platforms using guest mode');

  try {
    AudioService().initialize();
  } catch (e) {
    print('[main] AudioService.initialize() failed: $e');
  }

  try {
    await ConnectivityService().initialize();
  } catch (e) {
    print('[main] ConnectivityService.initialize() failed: $e');
  }

  try {
    await DownloadsManager().initialize();
  } catch (e) {
    print('[main] DownloadsManager.initialize() failed: $e');
  }

  try {
    await AuthService().initialize();
  } catch (e) {
    print('[main] AuthService.initialize() failed: $e');
  }

  try {
    await CloudSyncService().initialize();
  } catch (e) {
    print('[main] CloudSyncService.initialize() failed: $e');
  }

  try {
    final songs = await fetchSongs();
    await FavoritesManager().loadFavorites(songs);
  } catch (e) {
    print('[main] Favorites load failed: $e');
  }

  print('[main] initialization complete');
}

class MyApp extends StatelessWidget {
  final Future<void> initialization;

  const MyApp({super.key, required this.initialization});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Music Player",
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF1DB954), // Spotify Green
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1a1a1a),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: const Color(0xFF1DB954),
          inactiveTrackColor: Colors.grey.shade800,
          thumbColor: Colors.white,
          trackHeight: 4,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1DB954),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
        ),
      ),
      home: FutureBuilder<void>(
        future: initialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              backgroundColor: Color(0xFF121212),
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          return AuthListener();
        },
      ),
    );
  }
}

/// Widget that listens to auth state and routes accordingly
class AuthListener extends StatelessWidget {
  final AuthService _authService = AuthService();

  AuthListener({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _authService,
      builder: (context, _) {
        // Show LoginScreen only if explicitly logged out (after sign-out)
        // Show WelcomeScreen for both signed-in users and guests
        // Guests can browse but won't have cloud sync features
        if (_authService.isLoggedIn) {
          return const WelcomeScreen();
        } else {
          // Check if user has visited before (guest browsing)
          // For now, show LoginScreen which allows both sign-in and guest access
          return const LoginScreen();
        }
      },
    );
  }
}
