import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:wisepaise/models/user_model.dart';
import 'package:wisepaise/providers/api_provider.dart';
import 'package:wisepaise/screen/home_page.dart';
import 'package:wisepaise/utils/toast.dart';
import 'package:wisepaise/utils/utils.dart';

class AuthProvider extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      /*'https://www.googleapis.com/auth/userinfo.profile',*/
      'https://www.googleapis.com/auth/contacts.readonly',
    ],
  );

  GoogleSignInAccount? user;
  Map<String, dynamic>? thisUser;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;

  String? get error => _error;

  setUser(Map<String, dynamic> user) {
    thisUser = user;
    notifyListeners();
  }

  Future<GoogleSignInAccount?> getSignedInUser() async {
    user = _googleSignIn.currentUser;
    user ??= await _googleSignIn.signInSilently();
    return user;
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      _setLoading(true);
      _clearError();

      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        _setError('Google sign-in cancelled');
        Toasts.show(context, 'Sign-in was cancelled', type: ToastType.warning);
        return;
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;
      final String? accessToken = auth.accessToken;

      if (idToken == null) {
        _setError('Failed to get ID token');
        Toasts.show(
          context,
          'Failed to get authentication token',
          type: ToastType.error,
        );
        return;
      }

      user = account;

      ApiProvider api = Provider.of(context, listen: false);
      UserModel myUser = UserModel(
        userId: account.id,
        userName: account.displayName ?? '',
        userEmail: account.email,
        userImageUrl: account.photoUrl ?? '',
        userCreatedOn: formatDate(DateTime.now(), pattern: 'yyyy-MM-dd'),
      );
      await api.createUser(context, myUser.toJson()).then((Response resp) {
        if (resp.statusCode == HttpStatus.ok) {
          setUser(resp.data);
        }
      });
      notifyListeners();

      Toasts.show(
        context,
        'Welcome back, ${account.displayName ?? account.email}!',
        type: ToastType.success,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MyDashboardPage()),
      );
    } catch (e) {
      _setError('Google sign-in failed: $e');
      Toasts.show(
        context,
        'Sign-in failed. Please try again.',
        type: ToastType.error,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut(
    BuildContext context, {
    String source = 'signout',
  }) async {
    try {
      _setLoading(true);
      await _googleSignIn.signOut();
      user = null;
      notifyListeners();
      Toasts.show(
        context,
        source == 'signout'
            ? 'You have been signed out'
            : 'User Account Deleted',
        type: ToastType.info,
      );
    } catch (e) {
      _setError('Sign out failed: $e');
      Toasts.show(
        context,
        'Failed to sign out. Please try again.',
        type: ToastType.error,
      );
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> isUserLoggedIn() async {
    try {
      final user = await getSignedInUser();
      return user != null;
    } catch (_) {
      return false;
    }
  }
}
