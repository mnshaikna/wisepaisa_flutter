import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  bool _isConnected = true;

  bool get isConnected => _isConnected;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityProvider() {
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
    _initCheck();
  }

  Future<void> _initCheck() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final connected = results.any(
      (result) =>
          (result == ConnectivityResult.wifi ||
              result == ConnectivityResult.mobile),
    );

    if (connected != _isConnected) {
      _isConnected = connected;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
