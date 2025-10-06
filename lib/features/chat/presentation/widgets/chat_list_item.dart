import 'package:flutter/material.dart';
import '../../../auth/domain/entities/user.dart';

class ChatListItem extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: Text(
          user.name[0].toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(user.name),
      subtitle: Text(user.isOnline ? 'Online' : 'Offline'),
      onTap: onTap,
    );
  }
}
