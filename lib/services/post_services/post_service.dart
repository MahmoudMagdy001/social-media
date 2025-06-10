import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:facebook_clone/models/post_data_model.dart';
import 'package:facebook_clone/models/comments_model.dart';
import 'package:flutter/foundation.dart';

class PostService {
  // Constants
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);
  static const String _usersTable = 'users';
  static const String _postsTable = 'posts';
  static const String _commentsTable = 'comments';
  static const String _likesTable = 'likes';
  static const String _storageBucket = 'post-images';

  // Supabase instance
  final supabase.SupabaseClient _supabase;

  /// Creates a new instance of [PostService]
  PostService({supabase.SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? supabase.Supabase.instance.client;

  /// Executes a Supabase operation with retry logic
  Future<T> _executeWithRetry<T>(Future<T> Function() operation) async {
    int retryCount = 0;
    while (retryCount < _maxRetries) {
      try {
        return await operation();
      } catch (e) {
        retryCount++;
        if (retryCount == _maxRetries) {
          debugPrint('Operation failed after $_maxRetries attempts: $e');
          rethrow;
        }
        await Future.delayed(_retryDelay * retryCount);
      }
    }
    throw Exception('Operation failed after $_maxRetries attempts');
  }

  Future<String> _uploadPostImage(File imageFile, String userId) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = 'post_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName';

      debugPrint('Uploading post image to path: $filePath');

      await _supabase.storage.from(_storageBucket).upload(
            filePath,
            imageFile,
            fileOptions: supabase.FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      // Get the public URL
      final imageUrl =
          _supabase.storage.from(_storageBucket).getPublicUrl(filePath);

      if (imageUrl.isEmpty) {
        throw Exception('Failed to get public URL for uploaded image');
      }

      debugPrint('Post image uploaded successfully. URL: $imageUrl');
      return '$filePath|$imageUrl'; // Return both path and URL
    } on supabase.StorageException catch (e) {
      debugPrint('Storage error uploading post image: [31m${e.message}[0m');
      if (e.message.contains('row-level security policy')) {
        throw Exception(
            'Unable to upload post image. Please make sure you have the correct permissions and the storage bucket is properly configured.');
      }
      rethrow;
    } catch (e) {
      debugPrint('Error uploading post image: $e');
      rethrow;
    }
  }

  Future<void> createPost({
    required String postText,
    required supabase.User user,
    File? imageFile,
  }) async {
    if (postText.trim().isEmpty && imageFile == null) {
      throw ArgumentError('Post must contain either text or an image');
    }
    if (user.id.isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }

    await _executeWithRetry(() async {
      String? postImageUrl;
      String? postImagePath;
      if (imageFile != null) {
        final imageData = await _uploadPostImage(imageFile, user.id);
        final parts = imageData.split('|');
        postImagePath = parts[0];
        postImageUrl = parts[1];
      }

      final userData =
          await _supabase.from(_usersTable).select().eq('id', user.id).single();

      final post = {
        'user_id': user.id,
        'username': userData['display_name'] ?? 'Anonymous',
        'profile_image_url': userData['profile_image'] ?? '',
        'post_text': postText.trim(),
        'post_image_url': postImageUrl,
        'post_image_path': postImagePath, // Store the storage path
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'shares_count': 0,
      };

      await _supabase.from(_postsTable).insert(post);
    });
  }

  Stream<List<PostDataModel>> getPosts() {
    try {
      return _supabase
          .from(_postsTable)
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .map((events) => events.map(_mapToPost).toList());
    } catch (e) {
      debugPrint('Error getting posts: $e');
      rethrow;
    }
  }

  Future<void> addCommentToPost({
    required String postId,
    required String commentText,
    required supabase.User user,
  }) async {
    if (postId.isEmpty) throw ArgumentError('Post ID cannot be empty');
    if (commentText.trim().isEmpty) {
      throw ArgumentError('Comment text cannot be empty');
    }

    final userData =
        await _supabase.from(_usersTable).select().eq('id', user.id).single();

    await _executeWithRetry(() async {
      final comment = {
        'post_id': postId,
        'user_id': user.id,
        'username': userData['display_name'] ?? 'Anonymous',
        'profile_image_url': userData['profile_image'] ?? '',
        'comment_text': commentText.trim(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from(_commentsTable).insert(comment);
    });
  }

  Future<void> addLike({
    required String postId,
    required String userId,
  }) async {
    if (postId.isEmpty) throw ArgumentError('Post ID cannot be empty');
    if (userId.isEmpty) throw ArgumentError('User ID cannot be empty');

    final userData = await _supabase
        .from(_usersTable)
        .select('display_name')
        .eq('id', userId)
        .single();

    await _executeWithRetry(() async {
      await _supabase.from(_likesTable).insert({
        'post_id': postId,
        'user_id': userId,
        'display_name': userData['display_name'] ?? 'Anonymous',
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('User $userId liked the post $postId');
    });
  }

  Future<void> removeLike({
    required String postId,
    required String userId,
  }) async {
    if (postId.isEmpty) throw ArgumentError('Post ID cannot be empty');
    if (userId.isEmpty) throw ArgumentError('User ID cannot be empty');

    await _executeWithRetry(() async {
      await _supabase
          .from(_likesTable)
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
      debugPrint('User $userId unliked the post $postId');
    });
  }

  Stream<bool> hasUserLikedPost(
      {required String postId, required String userId}) {
    if (postId.isEmpty) throw ArgumentError('Post ID cannot be empty');
    if (userId.isEmpty) throw ArgumentError('User ID cannot be empty');

    return _supabase.from(_likesTable).stream(primaryKey: ['id']).map(
        (events) => events.any(
            (like) => like['post_id'] == postId && like['user_id'] == userId));
  }

  Stream<List<Map<String, dynamic>>> getLikesForPost({required String postId}) {
    return _supabase
        .from(_likesTable)
        .stream(primaryKey: ['id']).map((events) => events
            .where((like) => like['post_id'] == postId)
            .map((like) => {
                  'userId': like['user_id'],
                  'display_name': like['display_name'],
                  'timestamp': DateTime.parse(like['created_at']),
                })
            .toList());
  }

  Stream<List<CommentModel>> getCommentsForPost({required String postId}) {
    return _supabase
        .from(_commentsTable)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((events) => events
            .where((comment) => comment['post_id'] == postId)
            .map((comment) => CommentModel.fromMap(comment, comment['id']))
            .toList());
  }

  PostDataModel _mapToPost(Map<String, dynamic> data) {
    return PostDataModel.fromMap(data, data['id']);
  }

  Future<void> deletePost({
    required String postId,
    required String userId,
  }) async {
    if (postId.isEmpty) throw ArgumentError('Post ID cannot be empty');
    if (userId.isEmpty) throw ArgumentError('User ID cannot be empty');

    await _executeWithRetry(() async {
      final post =
          await _supabase.from(_postsTable).select().eq('id', postId).single();

      if (post['user_id'] != userId) {
        throw Exception('Not authorized to delete this post');
      }

      final postImagePath = post['post_image_path'];
      if (postImagePath != null && postImagePath.isNotEmpty) {
        try {
          debugPrint(
              'Attempting to delete image at storage path: $postImagePath');
          await _supabase.storage.from(_storageBucket).remove([postImagePath]);
          debugPrint('Image deleted successfully from storage');
        } catch (e) {
          debugPrint('Failed to delete post image from storage: $e');
        }
      }

      // Delete the post
      await _supabase.from(_postsTable).delete().eq('id', postId);
    });
  }

  Future<void> updatePost({
    required String postId,
    required String userId,
    required String postText,
  }) async {
    if (postId.isEmpty) throw ArgumentError('Post ID cannot be empty');
    if (userId.isEmpty) throw ArgumentError('User ID cannot be empty');
    if (postText.trim().isEmpty) {
      throw ArgumentError('Post text cannot be empty');
    }

    await _executeWithRetry(() async {
      final post =
          await _supabase.from(_postsTable).select().eq('id', postId).single();

      if (post['user_id'] != userId) {
        throw Exception('Not authorized to update this post');
      }

      await _supabase.from(_postsTable).update({
        'post_text': postText.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', postId);
    });
  }

  Future<void> updateComment({
    required String postId,
    required String commentId,
    required String newCommentText,
    required String userId,
  }) async {
    if (postId.isEmpty) throw ArgumentError('Post ID cannot be empty');
    if (commentId.isEmpty) throw ArgumentError('Comment ID cannot be empty');
    if (newCommentText.trim().isEmpty) {
      throw ArgumentError('Comment text cannot be empty');
    }
    if (userId.isEmpty) throw ArgumentError('User ID cannot be empty');

    await _executeWithRetry(() async {
      final comment = await _supabase
          .from(_commentsTable)
          .select()
          .eq('id', commentId)
          .single();

      if (comment['user_id'] != userId) {
        throw Exception('Not authorized to update this comment');
      }

      await _supabase.from(_commentsTable).update({
        'comment_text': newCommentText.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', commentId);
    });
  }

  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    if (postId.isEmpty) throw ArgumentError('Post ID cannot be empty');
    if (commentId.isEmpty) throw ArgumentError('Comment ID cannot be empty');

    await _executeWithRetry(() async {
      await _supabase
          .from(_commentsTable)
          .select()
          .eq('id', commentId)
          .single();

      await _supabase.from(_commentsTable).delete().eq('id', commentId);
    });
  }
}
