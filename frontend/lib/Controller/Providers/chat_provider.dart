import 'package:flutter/material.dart';
import 'package:frontend/Controller/Api%20Services/api_services.dart';
import 'package:frontend/Controller/Scoket%20Services/socket_services.dart';
import 'package:frontend/Model/conversation_model.dart';
import 'package:frontend/Model/message_model.dart';
import 'package:frontend/Model/user_model.dart';

class ChatProvider extends ChangeNotifier {
  final ApiServices apiService;
  final SocketService socketService;

  List<Conversation> _conversations = [];
  final Map<String, List<Message>> _messages = {};
  List<User> _searchResults = [];
  final Map<String, bool> _typingStatus = {};
  final Map<String, String> _onlineStatus = {};

  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  ChatProvider({required this.apiService, required this.socketService}) {
    _initSocketListeners();
    _loadCurrentUser();
  }

  // Load current user from storage service
  Future<void> _loadCurrentUser() async {
    _currentUser = await apiService.storageService?.getUser();
  }

  // Getters
  List<Conversation> get conversations => _conversations;
  List<Message> getMessages(String userId) => _messages[userId] ?? [];
  List<User> get searchResults => _searchResults;
  bool isUserTyping(String userId) => _typingStatus[userId] ?? false;
  String getUserStatus(String userId) => _onlineStatus[userId] ?? 'offline';
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize socket listeners
  void _initSocketListeners() {
    // Listen for new messages
    socketService.onNewMessage((message) {
      _addMessageToChat(message);
      _updateConversationWithMessage(message);
      notifyListeners();
    });

    // Listen for sent message confirmations
    socketService.onMessageSent((message) {
      _addMessageToChat(message);
      _updateConversationWithMessage(message);
      notifyListeners();
    });

    // Listen for message read status updates
    socketService.onMessageRead((messageId) {
      _updateMessageReadStatus(messageId);
      notifyListeners();
    });

    // Listen for typing status updates
    socketService.onUserTyping((userId, isTyping) {
      _typingStatus[userId] = isTyping;
      notifyListeners();
    });

    // Listen for user online status updates
    socketService.onUserStatus((userId, status) {
      _onlineStatus[userId] = status;
      notifyListeners();
    });
  }

  // Add message to chat
  void _addMessageToChat(Message message) {
    final partnerId = message.sender?.id == _currentUser?.id
        ? message.receiver?.id
        : message.sender?.id;

    if (partnerId == null) return;

    if (!_messages.containsKey(partnerId)) {
      _messages[partnerId] = [];
    }

    // Check if message already exists
    final index = _messages[partnerId]!.indexWhere((m) => m.id == message.id);
    if (index >= 0) {
      _messages[partnerId]![index] = message;
    } else {
      _messages[partnerId]!.add(message);
      // Sort messages by date
      _messages[partnerId]!.sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        return a.createdAt!.compareTo(b.createdAt!);
      });
    }
  }

  // Update conversation list with new message
  void _updateConversationWithMessage(Message message) {
    // Determine partner
    final currentUserId = _currentUser?.id;
    if (currentUserId == null) return;

    final partnerId = message.sender?.id == currentUserId
        ? message.receiver?.id
        : message.sender?.id;
    final partner =
        message.sender?.id == currentUserId ? message.receiver : message.sender;

    if (partnerId == null || partner == null) return;

    // Find existing conversation
    final index = _conversations.indexWhere((c) => c.partner?.id == partnerId);

    if (index >= 0) {
      // Update existing conversation
      final oldConversation = _conversations[index];
      final unreadCount =
          message.sender?.id != currentUserId && message.read != true
              ? (oldConversation.unreadCount ?? 0) + 1
              : oldConversation.unreadCount;

      _conversations[index] = Conversation(
        partner: partner,
        latestMessage: message,
        unreadCount: unreadCount,
      );

      // Move conversation to top
      if (index > 0) {
        final conversation = _conversations.removeAt(index);
        _conversations.insert(0, conversation);
      }
    } else {
      // Create new conversation
      final unreadCount =
          message.sender?.id != currentUserId && message.read != true ? 1 : 0;

      _conversations.insert(
        0,
        Conversation(
          partner: partner,
          latestMessage: message,
          unreadCount: unreadCount,
        ),
      );
    }
  }

  // Update message read status
  void _updateMessageReadStatus(String messageId) {
    // Update in all message lists
    _messages.forEach((userId, messages) {
      final index = messages.indexWhere((m) => m.id == messageId);
      if (index >= 0) {
        final message = messages[index];
        messages[index] = Message(
          id: message.id,
          sender: message.sender,
          receiver: message.receiver,
          content: message.content,
          createdAt: message.createdAt,
          read: true,
        );
      }
    });

    // Update in conversations
    for (int i = 0; i < _conversations.length; i++) {
      final conversation = _conversations[i];
      if (conversation.latestMessage?.id == messageId) {
        _conversations[i] = Conversation(
          partner: conversation.partner,
          latestMessage: Message(
            id: conversation.latestMessage?.id,
            sender: conversation.latestMessage?.sender,
            receiver: conversation.latestMessage?.receiver,
            content: conversation.latestMessage?.content,
            createdAt: conversation.latestMessage?.createdAt,
            read: true,
          ),
          unreadCount: (conversation.unreadCount ?? 0) > 0
              ? (conversation.unreadCount ?? 0) - 1
              : 0,
        );
        break;
      }
    }
  }

  // Load conversations
  Future<void> loadConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _conversations = await apiService.getConversations();

      // Refresh current user
      await _loadCurrentUser();

      // Update online status for all users
      for (final conversation in _conversations) {
        if (conversation.partner?.id != null) {
          _onlineStatus[conversation.partner!.id!] = 'offline';
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load messages for a specific user
  Future<void> loadMessages(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final messages = await apiService.getMessages(userId);

      // Clear existing messages for this user
      _messages[userId] = [];

      // Add messages to the chat
      for (final message in messages) {
        _addMessageToChat(message);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Search users
  Future<void> searchUsers(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await apiService.searchUsers(query);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Send message
  void sendMessage(String receiverId, String content) {
    socketService.sendMessage(receiverId, content);
  }

  // Mark message as read
  void markMessageAsRead(String messageId) {
    socketService.markAsRead(messageId);
  }

  // Send typing status
  void sendTyping(String receiverId, bool isTyping) {
    socketService.sendTyping(receiverId, isTyping);
  }

  // Clear search results
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
