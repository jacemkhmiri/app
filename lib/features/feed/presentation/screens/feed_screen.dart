import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/feed_provider.dart';
import '../../../auth/presentation/providers/user_provider.dart';
import '../../../auth/domain/entities/user.dart';
import '../widgets/post_card.dart';
import '../widgets/create_post_dialog.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = Provider.of<FeedProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Column(
      children: [
        _buildSearchBar(userProvider),
        Expanded(
          child: _isSearching
              ? _buildSearchResults()
              : _buildFeedContent(feedProvider, userProvider),
        ),
      ],
    );
  }

  Widget _buildSearchBar(UserProvider userProvider) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search users...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (value) {
          setState(() {
            _searchResults = userProvider.searchUsers(value);
            _isSearching = value.isNotEmpty;
          });
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text(
          'No users found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Text(
                user.name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(user.name),
            subtitle: Text(user.isOnline ? 'Online' : 'Offline'),
            trailing: ElevatedButton(
              onPressed: () => _addUser(user),
              child: const Text('Add'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedContent(FeedProvider feedProvider, UserProvider userProvider) {
    return Column(
      children: [
        _buildCreatePostCard(feedProvider, userProvider),
        Expanded(
          child: feedProvider.posts.isEmpty
              ? const Center(
                  child: Text(
                    'No posts yet.\nBe the first to post something!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: feedProvider.posts.length,
                  itemBuilder: (context, index) {
                    final post = feedProvider.posts[index];
                    return PostCard(post: post);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCreatePostCard(FeedProvider feedProvider, UserProvider userProvider) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: Icon(Icons.person, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showCreatePostDialog(feedProvider, userProvider),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        "What's on your mind?",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
    });
  }

  void _addUser(User user) {
    Provider.of<UserProvider>(context, listen: false).discoverUser(user);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${user.name} to discovered users!'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  void _showCreatePostDialog(FeedProvider feedProvider, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => CreatePostDialog(
        feedProvider: feedProvider,
        userProvider: userProvider,
      ),
    );
  }
}