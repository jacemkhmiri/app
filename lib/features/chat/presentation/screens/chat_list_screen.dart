import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../../../auth/presentation/providers/user_provider.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/chat.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
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
    final chatProvider = Provider.of<ChatProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;

    return Column(
      children: [
        _buildSearchBar(userProvider),
        Expanded(
          child: _isSearching
              ? _buildSearchResults(userProvider, chatProvider)
              : _buildChatList(chatProvider, userProvider, currentUser),
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
          hintText: 'Search users to start a chat...',
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

  Widget _buildSearchResults(UserProvider userProvider, ChatProvider chatProvider) {
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
              onPressed: () => _startChatWithUser(user, userProvider, chatProvider),
              child: const Text('Start Chat'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatList(ChatProvider chatProvider, UserProvider userProvider, User? currentUser) {
    if (chatProvider.chats.isEmpty) {
      return const Center(
        child: Text(
          'No chats yet.\nStart a new conversation!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: chatProvider.chats.length,
      itemBuilder: (context, index) {
        final chat = chatProvider.chats[index];
        final lastMessage = chat.messages.isNotEmpty ? chat.messages.last : null;
        final participantNames = _getParticipantNames(chat, userProvider, currentUser);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            title: Text(participantNames),
            subtitle: Text(lastMessage?.content ?? 'No messages yet'),
            trailing: Text(
              '${chat.lastActivity.hour.toString().padLeft(2, '0')}:${chat.lastActivity.minute.toString().padLeft(2, '0')}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            onTap: () => _openChat(chat),
          ),
        );
      },
    );
  }

  String _getParticipantNames(Chat chat, UserProvider userProvider, User? currentUser) {
    return chat.participantIds
        .where((id) => id != currentUser?.id)
        .map((id) {
      try {
        return userProvider.allUsers.firstWhere((u) => u.id == id).name;
      } catch (e) {
        return 'Unknown User';
      }
    }).join(', ');
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
    });
  }

  void _startChatWithUser(User user, UserProvider userProvider, ChatProvider chatProvider) {
    final newChat = Chat(
      id: 'chat_${DateTime.now().millisecondsSinceEpoch}',
      participantIds: [userProvider.currentUser!.id, user.id],
      messages: [],
      lastActivity: DateTime.now(),
    );
    chatProvider.addChat(newChat);
    userProvider.discoverUser(user);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(chat: newChat),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Started chat with ${user.name}!'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  void _openChat(Chat chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(chat: chat),
      ),
    );
  }
}