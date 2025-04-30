import 'package:flutter/material.dart';
import 'package:frontend/Controller/Providers/auth_provider.dart';
import 'package:frontend/Controller/Providers/chat_provider.dart';
import 'package:frontend/View/Interface/chat_page.dart';
import 'package:frontend/View/Interface/profile_page.dart';
import 'package:frontend/View/Interface/search_page.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Load conversations when the page is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Synk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body:
          chatProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : chatProvider.conversations.isEmpty
              ? _buildEmptyState()
              : _buildConversationList(chatProvider),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No conversations yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start chatting by searching for users',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
            icon: const Icon(Icons.search),
            label: const Text('Find Users'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList(ChatProvider chatProvider) {
    return RefreshIndicator(
      onRefresh: () => chatProvider.loadConversations(),
      child: ListView.builder(
        itemCount: chatProvider.conversations.length,
        itemBuilder: (context, index) {
          final conversation = chatProvider.conversations[index];
          final partner = conversation.partner;
          final message = conversation.latestMessage;

          if (partner == null) return const SizedBox.shrink();

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              backgroundImage:
                  partner.profilePicture != null
                      ? NetworkImage(partner.profilePicture!)
                      : null,
              child:
                  partner.profilePicture == null
                      ? Text(
                        partner.name?.substring(0, 1).toUpperCase() ?? '?',
                        style: const TextStyle(color: Colors.white),
                      )
                      : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    partner.name ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (message != null)
                  Text(
                    _formatTimestamp(message.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
            subtitle: Row(
              children: [
                Expanded(
                  child: Text(
                    message?.content ?? 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          conversation.unreadCount != null &&
                                  conversation.unreadCount! > 0
                              ? Colors.black
                              : Colors.grey[600],
                      fontWeight:
                          conversation.unreadCount != null &&
                                  conversation.unreadCount! > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                ),
                if (conversation.unreadCount != null &&
                    conversation.unreadCount! > 0)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      conversation.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ChatPage(
                        userId: partner.id!,
                        userName: partner.name ?? 'Unknown',
                        profilePicture: partner.profilePicture,
                      ),
                ),
              ).then((_) {
                // Refresh conversations when returning from chat
                chatProvider.loadConversations();
              });
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
