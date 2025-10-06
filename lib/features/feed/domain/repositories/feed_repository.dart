import '../entities/post.dart';
import '../../../../core/errors/failures.dart';

abstract class FeedRepository {
  Future<({Failure? failure, List<Post>? data})> getPosts();
  Future<({Failure? failure, Post? data})> getPostById(String id);
  Future<({Failure? failure, Post? data})> createPost(Post post);
  Future<({Failure? failure, bool? data})> likePost(String postId, String userId);
  Future<({Failure? failure, bool? data})> deletePost(String postId);
  Future<({Failure? failure, List<Post>? data})> getUserPosts(String userId);
  Future<({Failure? failure, List<Post>? data})> getSamplePosts();
}
