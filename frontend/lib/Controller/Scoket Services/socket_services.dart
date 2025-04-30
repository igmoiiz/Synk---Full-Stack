// lib/services/socket_service.dart
import 'dart:developer';

import 'package:frontend/Controller/Local%20Storage/storage_services.dart';
import 'package:frontend/Model/message_model.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  String? baseUrl;
  StorageService? storageService;
  IO.Socket? socket;

  SocketService({required this.baseUrl, required this.storageService});

  // Initialize socket connection
  Future<void> initSocket() async {
    // Get auth token
    final token = await storageService?.getToken();

    if (token == null) {
      throw Exception('User not authenticated');
    }

    // Connect to socket server with token
    socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .disableAutoConnect()
          .build(),
    );

    socket!.connect();

    // Set up connection event listeners
    socket!.onConnect((_) {
      log('Socket.IO connected');
    });

    socket!.onConnectError((error) {
      log('Connection error: $error');
    });

    socket!.onError((error) {
      log('Socket error: $error');
    });

    socket!.onDisconnect((_) {
      log('Socket.IO disconnected');
    });
  }

  // Send a message to another user
  void sendMessage(String receiverId, String content) {
    if (socket != null && socket!.connected) {
      socket!.emit('sendMessage', {
        'receiverId': receiverId,
        'content': content,
      });
    }
  }

  // Mark a message as read
  void markAsRead(String messageId) {
    if (socket != null && socket!.connected) {
      socket!.emit('markAsRead', {'messageId': messageId});
    }
  }

  // Send typing status
  void sendTyping(String receiverId, bool isTyping) {
    if (socket != null && socket!.connected) {
      socket!.emit('typing', {'receiverId': receiverId, 'isTyping': isTyping});
    }
  }

  // Listen for new messages
  void onNewMessage(Function(Message) callback) {
    socket?.on('newMessage', (data) {
      final message = Message.fromJson(data);
      callback(message);
    });
  }

  // Listen for sent message confirmations
  void onMessageSent(Function(Message) callback) {
    socket?.on('messageSent', (data) {
      final message = Message.fromJson(data);
      callback(message);
    });
  }

  // Listen for message read status updates
  void onMessageRead(Function(String) callback) {
    socket?.on('messageRead', (data) {
      final messageId = data['messageId'];
      callback(messageId);
    });
  }

  // Listen for typing status updates
  void onUserTyping(Function(String, bool) callback) {
    socket?.on('userTyping', (data) {
      final userId = data['userId'];
      final isTyping = data['isTyping'];
      callback(userId, isTyping);
    });
  }

  // Listen for user online status updates
  void onUserStatus(Function(String, String) callback) {
    socket?.on('userStatus', (data) {
      final userId = data['userId'];
      final status = data['status'];
      callback(userId, status);
    });
  }

  // Disconnect socket
  void disconnect() {
    socket?.disconnect();
    socket = null;
  }
}
