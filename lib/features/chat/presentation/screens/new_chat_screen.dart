import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/user_provider.dart';
import '../../../auth/domain/entities/user.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_list_item.dart';
import '../../domain/entities/chat.dart';

class NewChatScreen extends StatelessWidget {
  const NewChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Chat'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: userProvider.discoveredUsers.isEmpty
          ? const Center(
              child: Text(
                'No users discovered yet.\nUse the search feature on the login screen to find users.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: userProvider.discoveredUsers.length,
              itemBuilder: (context, index) {
                final user = userProvider.discoveredUsers[index];
                return ChatListItem(
                  user: user,
                  onTap: () => _startChatWithUser(context, user, userProvider, chatProvider),
                );
              },
            ),
    );
  }

  void _startChatWithUser(
    BuildContext context,
    User user,
    UserProvider userProvider,
    ChatProvider chatProvider,
  ) {
    final newChat = Chat(
      id: 'chat_${DateTime.now().millisecondsSinceEpoch}',
      participantIds: [userProvider.currentUser!.id, user.id],
      messages: [],
      lastActivity: DateTime.now(),
    );
    chatProvider.addChat(newChat);
    Navigator.pop(context);
  }
}
