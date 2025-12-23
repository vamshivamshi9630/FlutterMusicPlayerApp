import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Simple connectivity service that exposes whether the device is online.
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool _isOffline = false;
  bool get isOffline => _isOffline;

  Future<void> initialize() async {
    print('[ConnectivityService] initialize() start');
    try {
      final result = await _connectivity.checkConnectivity().timeout(const Duration(seconds: 4));
      _isOffline = result == ConnectivityResult.none;
      print('[ConnectivityService] initial connectivity: $result -> isOffline=$_isOffline');
      notifyListeners();

      _sub = _connectivity.onConnectivityChanged.listen((results) {
        final offline = results.contains(ConnectivityResult.none) || results.isEmpty;
        if (offline != _isOffline) {
          _isOffline = offline;
          print('[ConnectivityService] connectivity changed -> isOffline=$_isOffline');
          notifyListeners();
        }
      });
    } catch (e) {
      print('[ConnectivityService] initialize() error or timeout: $e - assuming online');
      _isOffline = false;
      notifyListeners();
    }
    print('[ConnectivityService] initialize() end');
  }

  void disposeService() {
    _sub?.cancel();
  }
}
