import 'package:flutter/material.dart';
import 'package:frontend/Controller/Providers/auth_provider.dart';
import 'package:frontend/Controller/Providers/chat_provider.dart';
import 'package:frontend/Model/message_model.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  final String userId;
  final String userName;
  final String? profilePicture;

  const ChatPage({
    super.key,
    required this.userId,
    required this.userName,
    this.profilePicture,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load messages for this user
      Provider.of<ChatProvider>(
        context,
        listen: false,
      ).loadMessages(widget.userId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Stop typing indicator when leaving the chat
    if (_isTyping) {
      Provider.of<ChatProvider>(
        context,
        listen: false,
      ).sendTyping(widget.userId, false);
    }
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      Provider.of<ChatProvider>(
        context,
        listen: false,
      ).sendMessage(widget.userId, text);
      _messageController.clear();

      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      // Reset typing indicator
      if (_isTyping) {
        Provider.of<ChatProvider>(
          context,
          listen: false,
        ).sendTyping(widget.userId, false);
        _isTyping = false;
      }
    }
  }

  void _onTypingChanged(String text) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    if (text.isNotEmpty && !_isTyping) {
      chatProvider.sendTyping(widget.userId, true);
      _isTyping = true;
    } else if (text.isEmpty && _isTyping) {
      chatProvider.sendTyping(widget.userId, false);
      _isTyping = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.id;
    final messages = chatProvider.getMessages(widget.userId);
    final isTyping = chatProvider.isUserTyping(widget.userId);
    final onlineStatus = chatProvider.getUserStatus(widget.userId);

    // Mark messages as read
    for (final message in messages) {
      if (message.sender?.id == widget.userId && message.read != true) {
        chatProvider.markMessageAsRead(message.id!);
      }
    }

    // Scroll to bottom when messages load
    if (messages.isNotEmpty && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              backgroundImage:
                  widget.profilePicture != null
                      ? NetworkImage(widget.profilePicture!)
                      : null,
              radius: 16,
              child:
                  widget.profilePicture == null
                      ? Text(
                        widget.userName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userName, style: const TextStyle(fontSize: 16)),
                Text(
                  isTyping ? 'typing...' : onlineStatus,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isTyping || onlineStatus == 'online'
                            ? Colors.green
                            : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child:
                chatProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : messages.isEmpty
                    ? const Center(
                      child: Text('No messages yet. Start a conversation!'),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.sender?.id == currentUserId;

                        return _buildMessageBubble(message, isMe);
                      },
                    ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: _onTypingChanged,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Color(0xFFF2F2F2),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 5,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content ?? '',
              style: TextStyle(
                fontSize: 16,
                color: isMe ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _formatTimestamp(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.black54,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.read == true ? Icons.done_all : Icons.done,
                    size: 12,
                    color: message.read == true ? Colors.white : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    if (now.day == timestamp.day &&
        now.month == timestamp.month &&
        now.year == timestamp.year) {
      // Today, show time only
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      // Another day, show date and time
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
