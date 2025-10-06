class Post {
  final String id;
  final String userId;
  final String content;
  final DateTime timestamp;
  final int likes;
  final List<String> likedBy;

  Post({
    required this.id,
    required this.userId,
    required this.content,
    required this.timestamp,
    this.likes = 0,
    this.likedBy = const [],
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Post && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}