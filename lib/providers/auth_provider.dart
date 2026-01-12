import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../models/user_profile.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  
  User? _user;
  UserProfile? _userProfile;
  bool _hasFactory = false;
  
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get hasFactory => _hasFactory;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _user != null;
  bool get hasProfile => _userProfile != null;

  AuthProvider() {
    _authService.user.listen((User? newUser) async {
      _user = newUser;
      if (newUser != null) {
        // Fetch profile and factory status when user state changes (e.g. auto login or manual login)
        // However, since listen runs mostly on stream events, we might want to do this fetching proactively during SignIn
        // But for auto-login (app restart), we need it here.
        await _fetchUserDetails(newUser.uid);
      } else {
        _userProfile = null;
        _hasFactory = false;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchUserDetails(String uid) async {
    try {
      _userProfile = await _profileService.getUserProfile(uid);
      _hasFactory = await _profileService.hasFactory(uid);
    } catch (e) {
      debugPrint("Error fetching user details: $e");
    } finally {
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Sign Up
  Future<bool> signUp(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.signUp(email: email, password: password);
      // Immediately sign out to prevent auto-login
      await _authService.signOut();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Sign In
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final credential = await _authService.signIn(email: email, password: password);
      if (credential?.user != null) {
        await _fetchUserDetails(credential!.user!.uid);
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _userProfile = null;
      _hasFactory = false;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Forgot Password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.sendPasswordResetEmail(email: email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Save Profile
  Future<bool> saveProfile(UserProfile profile) async {
    _setLoading(true);
    _setError(null);
    try {
      await _profileService.saveUserProfile(profile);
      _userProfile = profile;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Refresh Factory Status
  Future<void> refreshFactoryStatus() async {
    if (_user != null) {
      _hasFactory = await _profileService.hasFactory(_user!.uid);
      notifyListeners();
    }
  }
}
