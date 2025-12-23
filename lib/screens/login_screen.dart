import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/favorites_manager.dart';
import 'downloads_screen.dart';
import '../albums_screen.dart';
import '../favorites_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final CloudSyncService _cloudSyncService = CloudSyncService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1DB954),
                    Colors.green.shade700,
                  ],
                ),
              ),
              child: const Icon(
                Icons.music_note,
                size: 80,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 40),

            const Text(
              "Music Player",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "Sign in to sync your favorites",
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 60),

            // Google Sign-In Button
            AnimatedBuilder(
              animation: _authService,
              builder: (context, _) {
                return SizedBox(
                  width: 280,
                  child: ElevatedButton.icon(
                    onPressed: _authService.isLoading ? null : _handleGoogleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: _authService.isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black.withValues(alpha: 0.6),
                              ),
                            ),
                          )
                        : const Icon(Icons.login),
                    label: Text(
                      _authService.isLoading ? 'Signing in...' : 'Sign in with Google',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Continue as Guest Button
            SizedBox(
              width: 280,
              child: TextButton(
                onPressed: () {
                  // Guest browsing is allowed - users can browse albums and songs
                  // but won't have cloud sync features until they sign in
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  );
                },
                child: const Text(
                  'Continue as Guest',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1DB954),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Info Box
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why sign in?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '✓ Sync favorites across devices\n'
                    '✓ Access your music anywhere\n'
                    '✓ Cloud backup of preferences',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    print('[LoginScreen] Starting Google Sign-In flow...');

    final success = await _authService.signInWithGoogle();

    if (!mounted) return;

      if (success) {
        print('[LoginScreen] ✓ Sign-In successful');

        // Initialize cloud sync
        await _cloudSyncService.initialize();

        // Download favorites from cloud
        final cloudFavorites = await _cloudSyncService.downloadFavorites();

        if (cloudFavorites.isNotEmpty) {
          print('[LoginScreen] Syncing ${cloudFavorites.length} cloud favorites to local');
          // Update local favorites with cloud data
          final favoritesManager = FavoritesManager();
          for (var song in cloudFavorites) {
            favoritesManager.addFavorite(song);
          }
        }

        // Navigate to Welcome Screen and clear navigation history so
        // pressing back won't return to the sign-up screen.
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (route) => false,
          );
        }
      } else {
      print('[LoginScreen] ✗ Sign-In failed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sign-in failed. Please try again.'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Player'),
        elevation: 0,
        actions: [
          AnimatedBuilder(
            animation: authService,
            builder: (context, _) {
              if (!authService.isLoggedIn) {
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Row(
                      children: const [
                        Icon(Icons.person_outline, color: Colors.white70),
                        SizedBox(width: 8),
                        Text('Guest', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                );
              }

              // Logged-in: show profile avatar/menu
              // Logged-in: show profile avatar/menu
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: GestureDetector(
                    onTap: () => _showProfileMenu(context, authService),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey.shade800,
                          child: ClipOval(
                            child: authService.userPhotoUrl != null
                                ? Image.network(
                              authService.userPhotoUrl!,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback if image fails to load
                                return Center(
                                  child: Text(
                                    authService.userName?.substring(0, 1) ?? 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            )
                                : Center(
                              child: Text(
                                authService.userName?.substring(0, 1) ?? 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1DB954),
                    Colors.green.shade700,
                  ],
                ),
              ),
              child: const Icon(
                Icons.music_note,
                size: 80,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 40),

            const Text(
              "Welcome!",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              authService.isLoggedIn
                  ? "Welcome ${authService.userName ?? 'User'}"
                  : "Your favorite songs, all in one place",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 60),

            // Albums Button
            SizedBox(
              width: 280,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AlbumScreen()),
                  );
                },
                icon: const Icon(Icons.album),
                label: const Text(
                  "Browse Albums",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Favorites Button
            SizedBox(
              width: 280,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FavoritesScreen()),
                  );
                },
                icon: const Icon(Icons.favorite),
                label: const Text(
                  "My Favorites",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Downloaded Songs Button
            SizedBox(
              width: 280,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DownloadsScreen()),
                  );
                },
                icon: const Icon(Icons.download_done),
                label: const Text(
                  "Downloaded Songs",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context, AuthService authService) {
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 56, 0, 0),
      items: [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                authService.userName ?? 'User',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                authService.userEmail ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          child: const Text('Sign Out'),
          onTap: () async {
            await authService.signOut();
            if (context.mounted) {
              // Clear navigation stack and show only the signup/login screen.
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }
          },
        ),
      ],
    );
  }
}
