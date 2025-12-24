import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import '../config/secrets.dart';

late GoogleSignIn _googleSignIn;

class AuthService extends ChangeNotifier {
  /// Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Map<String, dynamic>? _user;
  bool _isLoading = false;
  bool _initialized = false;

  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;

  String? get userEmail => _user?['email'];
  String? get userName => _user?['displayName'];
  String? get userPhotoUrl => _user?['photoURL'];

  // ---------------- INIT ----------------

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      if (!Secrets.isConfigured) {
        debugPrint('[AuthService] OAuth not configured → guest mode');
        return;
      }

      if (kIsWeb) {
        _googleSignIn = GoogleSignIn(
          scopes: const ['email', 'profile'],
          clientId: Secrets.googleClientId, // Web client ID
        );
      } else {
        _googleSignIn = GoogleSignIn(
          scopes: const ['email', 'profile'], // mobile uses google-services.json / plist
        );
      }


      await _loadUserFromStorage();
      notifyListeners();
    } catch (e) {
      debugPrint('[AuthService] Initialization error: $e');
    }
  }

  // ---------------- STORAGE ----------------

  Future<void> _loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    final email = prefs.getString('user_email');
    final id = prefs.getString('user_id');

    if (email != null && id != null) {
      _user = {
        'uid': id,
        'email': email,
        'displayName': prefs.getString('user_name') ?? 'User',
        'photoURL': prefs.getString('user_photo_url'),
      };
    }
  }

  Future<void> _saveUserToStorage() async {
    if (_user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', _user!['uid']);
    await prefs.setString('user_email', _user!['email']);
    await prefs.setString('user_name', _user!['displayName']);
    await prefs.setString('user_photo_url', _user!['photoURL'] ?? '');
  }

  Future<void> _clearUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ---------------- SIGN IN ----------------

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 🔐 Make sure secrets / config exist
      if (!Secrets.isConfigured) {
        debugPrint('[AuthService] Google config missing');
        return false;
      }

      // 🖥️ Use desktop flow only for Windows
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
        return await _signInDesktop();
      }

      // 📲 Normal Google sign-in (Android / iOS / Web)
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('[AuthService] User canceled sign-in');
        return false;
      }

      _user = {
        'uid': googleUser.id,
        'email': googleUser.email,
        'displayName': googleUser.displayName ?? 'User',
        'photoURL': googleUser.photoUrl,
      };

      await _saveUserToStorage();
      return true;
    } catch (e, s) {
      debugPrint('[AuthService] Sign-in failed: $e');
      debugPrint('$s');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------- SIGN OUT ----------------

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (!kIsWeb && defaultTargetPlatform != TargetPlatform.windows) {
        await _googleSignIn.signOut();
      }
      _user = null;
      await _clearUserFromStorage();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------- DESKTOP OAUTH ----------------

  Future<bool> _signInDesktop() async {
    try {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final redirectUri = 'http://localhost:${server.port}';

      final authUrl = Uri.https(
        'accounts.google.com',
        '/o/oauth2/v2/auth',
        {
          'response_type': 'code',
          'client_id': Secrets.googleClientId,
          'redirect_uri': redirectUri,
          'scope': 'openid email profile',
          'access_type': 'offline',
          'prompt': 'consent',
        },
      );

      debugPrint('[AuthService] Opening browser for Google Sign-In');
      if (!await launchUrl(authUrl)) {
        await server.close();
        return false;
      }

      final request = await server.first;
      final code = request.uri.queryParameters['code'];

      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.html
        ..write('<h2>You can close this window now</h2>');
      await request.response.close();
      await server.close();

      if (code == null) return false;

      final tokenResponse = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'code': code,
          'client_id': Secrets.googleClientId,
          'client_secret': Secrets.googleClientSecret,
          'redirect_uri': redirectUri,
          'grant_type': 'authorization_code',
        },
      );

      if (tokenResponse.statusCode != 200) {
        debugPrint('[AuthService] Token exchange failed: ${tokenResponse.body}');
        return false;
      }

      final accessToken = jsonDecode(tokenResponse.body)['access_token'];
      if (accessToken == null) return false;

      final profileResponse = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v2/userinfo'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      final profile = jsonDecode(profileResponse.body);
      _user = {
        'uid': profile['id'],
        'email': profile['email'],
        'displayName': profile['name'],
        'photoURL': profile['picture'],
      };

      await _saveUserToStorage();
      notifyListeners();

      debugPrint('[AuthService] Desktop Google Sign-In success');
      return true;
    } catch (e) {
      debugPrint('[AuthService] Desktop OAuth error: $e');
      return false;
    }
  }
}
