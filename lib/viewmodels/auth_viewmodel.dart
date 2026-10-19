import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/firebase_auth_service.dart';

/// ViewModel for authentication business logic
/// Follows MVVM pattern - handles authentication logic
class AuthViewModel extends ChangeNotifier {
  final FirebaseAuthService _authService;
  StreamSubscription? _authStateSubscription;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  AuthViewModel(this._authService) {
    _initialize();
  }

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize and listen to auth state changes
  void _initialize() {
    // Check initial auth state
    _isAuthenticated = _authService.currentUser != null;

    // Listen to auth state changes
    _authStateSubscription = _authService.authStateChanges.listen(
      (user) {
        _isAuthenticated = user != null;
        notifyListeners();
      },
    );
  }

  /// Login with email and password using Firebase
  Future<bool> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _error = 'Email and password are required';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Auth state listener will update _isAuthenticated automatically
      _isLoading = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Signup with email and password using Firebase
  Future<bool> signup(String name, String email, String password) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _error = 'All fields are required';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        displayName: name,
      );
      // Auth state listener will update _isAuthenticated automatically
      _isLoading = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signOut();
      // Auth state listener will update _isAuthenticated automatically
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to sign out: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}

