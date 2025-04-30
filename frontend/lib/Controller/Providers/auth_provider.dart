import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/Controller/Api%20Services/api_services.dart';
import 'package:frontend/Controller/Local%20Storage/storage_services.dart';
import 'package:frontend/Model/user_model.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final ApiServices apiService;
  final StorageService storageService;

  AuthStatus _status = AuthStatus.initial;
  User? _currentUser;
  String? _error;
  bool _loading = false;

  AuthProvider({required this.apiService, required this.storageService}) {
    _checkAuthentication();
  }

  // Getters
  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  String? get error => _error;
  bool get isLoading => _loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // Check if user is already authenticated
  Future<void> _checkAuthentication() async {
    _loading = true;
    notifyListeners();

    try {
      final token = await storageService.getToken();
      if (token != null) {
        _currentUser = await storageService.getUser();
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Register
  Future<bool> register(String name, String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await apiService.register(name, email, password);
      _loading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await apiService.login(email, password);
      _status = AuthStatus.authenticated;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _loading = false;
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _loading = true;
    notifyListeners();

    try {
      await apiService.logout();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Update profile picture
  Future<bool> updateProfilePicture(File imageFile) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final profilePicture = await apiService.uploadProfilePicture(imageFile);

      // Update current user
      if (_currentUser != null) {
        _currentUser = User(
          id: _currentUser!.id,
          name: _currentUser!.name,
          email: _currentUser!.email,
          profilePicture: profilePicture,
        );
      }

      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
