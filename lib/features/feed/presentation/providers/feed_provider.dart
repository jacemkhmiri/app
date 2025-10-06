import 'package:flutter/foundation.dart';
import '../../domain/entities/post.dart';

class FeedProvider with ChangeNotifier {
  final List<Post> _posts = [];
  bool _hasInitialized = false;

  List<Post> get posts => _posts;

  Future<void> initializeSampleData() async {
    if (_hasInitialized) return;
    _hasInitialized = true;

    final samplePosts = [
      Post(
        id: 'post_1',
        userId: 'user_alice',
        content: 'Just finished building this amazing P2P messaging app! The decentralized approach is so much better than traditional social media. 🚀',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        likes: 5,
        likedBy: ['user_bob', 'user_charlie'],
      ),
      Post(
        id: 'post_2',
        userId: 'user_bob',
        content: 'Privacy matters! Love how this app keeps everything peer-to-peer without any central servers. No data harvesting here! 🔒',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        likes: 3,
        likedBy: ['user_alice'],
      ),
      Post(
        id: 'post_3',
        userId: 'user_charlie',
        content: 'The UI looks fantastic! Clean, modern design with smooth animations. Great work on the user experience! ✨',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        likes: 7,
        likedBy: ['user_alice', 'user_diana', 'user_eve'],
      ),
      Post(
        id: 'post_4',
        userId: 'user_diana',
        content: 'Real-time messaging without any middleman? Count me in! This is the future of communication. 🌟',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        likes: 4,
        likedBy: ['user_alice', 'user_bob'],
      ),
    ];

    _posts.addAll(samplePosts);
    notifyListeners();
  }

  void addPost(Post post) {
    _posts.insert(0, post);
    notifyListeners();
  }

  void likePost(String postId, String userId) {
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      final post = _posts[postIndex];
      final isLiked = post.likedBy.contains(userId);

      final updatedPost = Post(
        id: post.id,
        userId: post.userId,
        content: post.content,
        timestamp: post.timestamp,
        likes: isLiked ? post.likes - 1 : post.likes + 1,
        likedBy: isLiked
            ? (() {
                final newList = List<String>.from(post.likedBy);
                newList.remove(userId);
                return newList;
              })()
            : (() {
                final newList = List<String>.from(post.likedBy);
                newList.add(userId);
                return newList;
              })(),
      );
      _posts[postIndex] = updatedPost;
      notifyListeners();
    }
  }
}