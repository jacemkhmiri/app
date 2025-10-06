import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/user_provider.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../feed/presentation/providers/feed_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) {
      return const Center(
        child: Text('Please log in'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildUserAvatar(context, currentUser),
          const SizedBox(height: 16),
          _buildUserName(currentUser),
          const SizedBox(height: 8),
          _buildUserStatus(currentUser),
          const SizedBox(height: 24),
          _buildUserStats(context),
          const SizedBox(height: 24),
          _buildLogoutButton(context, userProvider),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context, User currentUser) {
    return CircleAvatar(
      radius: 50,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      child: Text(
        currentUser.name[0].toUpperCase(),
        style: const TextStyle(fontSize: 30, color: Colors.white),
      ),
    );
  }

  Widget _buildUserName(User currentUser) {
    return Text(
      currentUser.name,
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildUserStatus(User currentUser) {
    return Text(
      currentUser.isOnline ? 'Online' : 'Offline',
      style: TextStyle(
        color: currentUser.isOnline ? Colors.green : Colors.grey[600],
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildUserStats(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Your Stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  context,
                  '${Provider.of<UserProvider>(context).discoveredUsers.length}',
                  'Discovered Users',
                ),
                _buildStatColumn(
                  context,
                  '${Provider.of<ChatProvider>(context).chats.length}',
                  'Active Chats',
                ),
                _buildStatColumn(
                  context,
                  '${Provider.of<FeedProvider>(context).posts.where((p) => p.userId == Provider.of<UserProvider>(context).currentUser?.id).length}',
                  'Your Posts',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        Text(label),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, UserProvider userProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => userProvider.setUser(null),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        child: const Text('Logout'),
      ),
    );
  }
}
