import 'package:flutter/material.dart';
import '../providers/feed_provider.dart';
import '../../../auth/presentation/providers/user_provider.dart';
import '../../domain/entities/post.dart';

class CreatePostDialog extends StatefulWidget {
  final FeedProvider feedProvider;
  final UserProvider userProvider;

  const CreatePostDialog({
    super.key,
    required this.feedProvider,
    required this.userProvider,
  });

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.edit,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          const Text('Create Post'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            maxLines: 5,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: "What's happening?",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_controller.text.length}/500',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isPosting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isPosting ? null : _handlePost,
          child: _isPosting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Post'),
        ),
      ],
    );
  }

  Future<void> _handlePost() async {
    if (_controller.text.trim().isEmpty || widget.userProvider.currentUser == null) {
      return;
    }

    setState(() => _isPosting = true);

    // Simulate a small delay for better UX
    await Future.delayed(const Duration(milliseconds: 500));

    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: widget.userProvider.currentUser!.id,
      content: _controller.text.trim(),
      timestamp: DateTime.now(),
    );

    widget.feedProvider.addPost(newPost);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post published successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}