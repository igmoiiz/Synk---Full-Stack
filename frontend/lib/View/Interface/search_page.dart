import 'package:flutter/material.dart';
import 'package:frontend/Controller/Providers/chat_provider.dart';
import 'package:frontend/Model/user_model.dart';
import 'package:frontend/View/Interface/chat_page.dart';
import 'package:provider/provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      Provider.of<ChatProvider>(context, listen: false).searchUsers(query);
      setState(() {
        _hasSearched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Find Users')),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search by name or email',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _search,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(Icons.search),
                ),
              ],
            ),
          ),

          // Search Results
          Expanded(
            child:
                chatProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : !_hasSearched
                    ? const Center(
                      child: Text('Search for users to start chatting'),
                    )
                    : chatProvider.searchResults.isEmpty
                    ? const Center(child: Text('No users found'))
                    : ListView.builder(
                      itemCount: chatProvider.searchResults.length,
                      itemBuilder: (context, index) {
                        final user = chatProvider.searchResults[index];
                        return _buildUserListTile(user);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserListTile(User user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        backgroundImage:
            user.profilePicture != null
                ? NetworkImage(user.profilePicture!)
                : null,
        child:
            user.profilePicture == null
                ? Text(
                  user.name?.substring(0, 1).toUpperCase() ?? '?',
                  style: const TextStyle(color: Colors.white),
                )
                : null,
      ),
      title: Text(user.name ?? 'Unknown'),
      subtitle: Text(user.email ?? ''),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatPage(
                  userId: user.id!,
                  userName: user.name ?? 'Unknown',
                  profilePicture: user.profilePicture,
                ),
          ),
        );
      },
    );
  }
}
