import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/post.dart';
import '../../../auth/presentation/providers/user_provider.dart';
import '../../../auth/domain/entities/user.dart';
import '../providers/feed_provider.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isLiked = post.likedBy.contains(userProvider.currentUser?.id);

    final postUser = userProvider.allUsers
        .cast<User?>()
        .firstWhere((u) => u?.id == post.userId, orElse: () => null);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfo(context, postUser),
            const SizedBox(height: 12),
            Text(post.content),
            const SizedBox(height: 12),
            _buildPostActions(context, isLiked),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, User? postUser) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: Text(
            postUser?.name[0].toUpperCase() ?? '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          postUser?.name ?? 'Unknown User',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPostActions(BuildContext context, bool isLiked) {
    return Row(
      children: [
        _buildLikeButton(context, isLiked),
        const SizedBox(width: 12),
        _buildCommentButton(context),
        const Spacer(),
        _buildTimestamp(),
      ],
    );
  }

  Widget _buildLikeButton(BuildContext context, bool isLiked) {
    return GestureDetector(
      onTap: () => _handleLike(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isLiked
              ? Colors.red.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLiked ? Colors.red : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(isLiked),
                color: isLiked ? Colors.red : Colors.grey[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${post.likes}',
              style: TextStyle(
                color: isLiked ? Colors.red : Colors.grey[600],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCommentDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.comment_outlined,
              color: Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              '0',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimestamp() {
    return Text(
      _formatTimestamp(post.timestamp),
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 12,
      ),
    );
  }

  void _handleLike(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.currentUser != null) {
      Provider.of<FeedProvider>(context, listen: false)
          .likePost(post.id, userProvider.currentUser!.id);
    }
  }

  void _showCommentDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comment feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}