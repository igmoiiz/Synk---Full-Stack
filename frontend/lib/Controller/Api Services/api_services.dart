import 'dart:convert';
import 'dart:io';

import 'package:frontend/Controller/Local%20Storage/storage_services.dart';
import 'package:frontend/Model/conversation_model.dart';
import 'package:frontend/Model/message_model.dart';
import 'package:frontend/Model/user_model.dart';
import 'package:http/http.dart' as http;

class ApiServices {
  String? baseUrl;
  StorageService? storageService;

  ApiServices({required this.baseUrl, required this.storageService});

  // Get auth token from local storage
  Future<String?> get token async => await storageService?.getToken();

  // Create authenticated headers
  Future<Map<String, String>> get authHeaders async {
    final token = await this.token;
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Register new user
  Future<bool> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Registration failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Login user
  Future<User> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save token to storage
        await storageService?.saveToken(data['token']);

        // Save user data
        final user = User.fromJson(data['user']);
        await storageService?.saveUser(user);

        return user;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Login failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    await storageService?.clearAll();
  }

  // Update profile picture
  Future<String> uploadProfilePicture(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/profile-picture'),
      );

      // Add token to headers
      final token = await this.token;
      request.headers['Authorization'] = 'Bearer $token';

      // Add file to request
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Update user in storage with new profile picture
        final currentUser = await storageService?.getUser();
        if (currentUser != null) {
          final updatedUser = User(
            id: currentUser.id,
            name: currentUser.name,
            email: currentUser.email,
            profilePicture: data['profilePicture'],
          );
          await storageService?.saveUser(updatedUser);
        }

        return data['profilePicture'];
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['error'] ?? 'Failed to upload profile picture',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get conversations (chat list)
  Future<List<Conversation>> getConversations() async {
    try {
      final headers = await authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/conversations'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Conversation.fromJson(json)).toList();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get conversations');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get messages with a specific user
  Future<List<Message>> getMessages(String userId) async {
    try {
      final headers = await authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/messages/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Message.fromJson(json)).toList();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get messages');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Search users
  Future<List<User>> searchUsers(String query) async {
    try {
      final headers = await authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/users/search?query=$query'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to search users');
      }
    } catch (e) {
      rethrow;
    }
  }
}
