// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/Model/user_model.dart';

class StorageService {
  // Storage instance
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Token storage key
  static const String TOKEN_KEY = 'auth_token';
  // User storage key
  static const String USER_KEY = 'current_user';

  // Save token to secure storage
  Future<void> saveToken(String token) async {
    await _storage.write(key: TOKEN_KEY, value: token);
  }

  // Get token from secure storage
  Future<String?> getToken() async {
    return await _storage.read(key: TOKEN_KEY);
  }

  // Save user to secure storage
  Future<void> saveUser(User user) async {
    await _storage.write(key: USER_KEY, value: jsonEncode(user.toJson()));
  }

  // Get user from secure storage
  Future<User?> getUser() async {
    final userJson = await _storage.read(key: USER_KEY);

    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }

    return null;
  }

  // Delete a specific key
  Future<void> deleteKey(String key) async {
    await _storage.delete(key: key);
  }

  // Clear all stored data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
