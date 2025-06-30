import 'dart:io';
import 'package:facebook_clone/models/reels_model.dart';
import 'package:facebook_clone/core/utlis/execute_with_retry.dart';
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
  static const String _reelsTable = 'reels';

  static const String _commentsTable = 'comments';
  static const String _likesTable = 'likes';

  static const String _storageBucket = 'post-images';

  // Supabase instance
  final supabase.SupabaseClient _supabase;

  /// Creates a new instance of [PostService]
  PostService({supabase.SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? supabase.Supabase.instance.client;

  /// Executes a Supabase operation with retry logic

  Future<void> createPost({
    required String postText,
    required supabase.User user,
    File? imageFile,
    File? videoFile,
  }) async {
    if (postText.trim().isEmpty && imageFile == null && videoFile == null) {
      throw ArgumentError(
          'Post must contain either text, an image, or a video');
    }

    if (user.id.isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }

    String? postImageUrl;
    String? postImagePath;
    String? postVideoUrl;
    String? postVideoPath;

    // Upload image if provided
    if (imageFile != null) {
      final imageData = await _uploadPostImage(imageFile, user.id);
      final parts = imageData.split('|');
      if (parts.length != 2) {
        throw StateError('Invalid image data format');
      }
      postImagePath = parts[0];
      postImageUrl = parts[1];
    }

    // Upload video if provided
    if (videoFile != null) {
      final videoData = await _uploadPostVideo(videoFile, user.id);
      final parts = videoData.split('|');
      if (parts.length != 2) {
        throw StateError('Invalid video data format');
      }
      postVideoPath = parts[0];
      postVideoUrl = parts[1];
    }

    final userData = await _supabase
        .from(_usersTable)
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (userData == null) {
      throw StateError('User not found');
    }

    final timestamp = DateTime.now().toUtc().toIso8601String();

    // Shared metadata
    final commonData = {
      'user_id': user.id,
      'display_name': userData['display_name'] ?? 'Anonymous',
      'profile_image_url': userData['profile_image'] ?? '',
      'post_text': postText.trim(),
      'created_at': timestamp,
      'updated_at': timestamp,
      'shares_count': 0,
    };

    if (videoFile != null) {
      // Add video fields for reels only
      final reelData = {
        ...commonData,
        'post_video_url': postVideoUrl,
        'post_video_path': postVideoPath,
      };
      await _supabase.from(_reelsTable).insert(reelData);
    } else {
      // Add image fields for standard post (if any)
      final postData = {
        ...commonData,
        if (postImageUrl != null) 'post_image_url': postImageUrl,
        if (postImagePath != null) 'post_image_path': postImagePath,
      };
      await _supabase.from(_postsTable).insert(postData);
    }
  }

  Future<void> deletePost({
    required String postId,
    required String userId,
    bool isReel = false,
  }) async {
    if (postId.isEmpty) throw ArgumentError('Post ID cannot be empty');
    if (userId.isEmpty) throw ArgumentError('User ID cannot be empty');

    final String tableName = isReel ? _reelsTable : _postsTable;
    final String pathField = isReel ? 'post_video_path' : 'post_image_path';

    await executeWithRetry(() async {
      // Fetch the post/reel to verify ownership and get file path
      final post =
          await _supabase.from(tableName).select().eq('id', postId).single();

      if (post['user_id'] != userId) {
        throw Exception('Not authorized to delete this post');
      }

      // Delete the database record first
      await _supabase.from(tableName).delete().eq('id', postId);
      debugPrint(
          '${isReel ? "Reel" : "Post"} deleted successfully from database');

      // Handle file deletion after successful database operation
      final postFilePath = post[pathField] as String?;
      if (postFilePath != null && postFilePath.isNotEmpty) {
        try {
          await _supabase.storage.from(_storageBucket).remove([postFilePath]);
          debugPrint('File deleted successfully from storage');
        } catch (e) {
          debugPrint('Failed to delete post file from storage: $e');
          // Consider adding retry logic for storage deletion here if needed
        }
      }
    }, maxRetries: _maxRetries, retryDelay: _retryDelay);
  }

  Future<void> updatePost({
    required String postId,
    required String userId,
    String? updatedText,
    File? newImageFile,
    bool removeImage = false, // NEW
  }) async {
    if ((updatedText == null || updatedText.trim().isEmpty) &&
        newImageFile == null &&
        !removeImage) {
      throw ArgumentError(
          'Post must contain either updated text, a new image, or image removal');
    }

    await executeWithRetry(() async {
      final existingPost = await _supabase
          .from(_postsTable)
          .select()
          .eq('id', postId)
          .maybeSingle();

      if (existingPost == null) {
        throw StateError('Post not found');
      }

      if (existingPost['user_id'] != userId) {
        throw StateError('You are not authorized to update this post');
      }

      String? postImageUrl = existingPost['post_image_url'];
      String? postImagePath = existingPost['post_image_path'];

      // Handle image deletion
      if (removeImage && postImagePath != null && postImagePath.isNotEmpty) {
        try {
          await _supabase.storage.from(_storageBucket).remove([postImagePath]);
        } catch (_) {
          // Optionally log image deletion failure
        }
        postImageUrl = null;
        postImagePath = null;
      }

      // Handle image replacement
      if (newImageFile != null) {
        if (postImagePath != null && postImagePath.isNotEmpty) {
          try {
            await _supabase.storage
                .from(_storageBucket)
                .remove([postImagePath]);
          } catch (_) {}
        }

        final imageData = await _uploadPostImage(newImageFile, userId);
        final parts = imageData.split('|');
        if (parts.length != 2) {
          throw StateError('Invalid image data format: $imageData');
        }
        postImagePath = parts[0];
        postImageUrl = parts[1];
      }

      final updates = {
        if (updatedText != null) 'post_text': updatedText.trim(),
        'post_image_url': postImageUrl,
        'post_image_path': postImagePath,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      await _supabase.from(_postsTable).update(updates).eq('id', postId);
    }, maxRetries: _maxRetries, retryDelay: _retryDelay);
  }

  Future<List<PostDataModel>> getPosts() async {
    try {
      final response = await _supabase
          .from(_postsTable)
          .select()
          .order('created_at', ascending: false);

      // Defensive cast & mapping
      final data = response as List<dynamic>;

      return data.map<PostDataModel>((item) {
        final documentId = item['id'];
        return PostDataModel.fromMap(item, documentId);
      }).toList();
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting posts: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<List<ReelModel>> getReels() async {
    try {
      final response = await _supabase
          .from('reels')
          .select()
          .order('created_at', ascending: false);

      return (response as List).map((item) => ReelModel.fromMap(item)).toList();
    } catch (e) {
      debugPrint('Error fetching reels: $e');
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

    await executeWithRetry(() async {
      final comment = {
        'post_id': postId,
        'user_id': user.id,
        'display_name': userData['display_name'] ?? 'Anonymous',
        'profile_image_url': userData['profile_image'] ?? '',
        'comment_text': commentText.trim(),
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from(_commentsTable).insert(comment);
    }, maxRetries: _maxRetries, retryDelay: _retryDelay);
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

    await executeWithRetry(() async {
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
    }, maxRetries: _maxRetries, retryDelay: _retryDelay);
  }

  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    if (postId.isEmpty) throw ArgumentError('Post ID cannot be empty');
    if (commentId.isEmpty) throw ArgumentError('Comment ID cannot be empty');

    await executeWithRetry(() async {
      await _supabase
          .from(_commentsTable)
          .select()
          .eq('id', commentId)
          .single();

      await _supabase.from(_commentsTable).delete().eq('id', commentId);
    }, maxRetries: _maxRetries, retryDelay: _retryDelay);
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

    await executeWithRetry(() async {
      await _supabase.from(_likesTable).insert({
        'post_id': postId,
        'user_id': userId,
        'display_name': userData['display_name'] ?? 'Anonymous',
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('User $userId liked the post $postId');
    }, maxRetries: _maxRetries, retryDelay: _retryDelay);
  }

  Future<void> removeLike({
    required String postId,
    required String userId,
  }) async {
    if (postId.isEmpty) throw ArgumentError('Post ID cannot be empty');
    if (userId.isEmpty) throw ArgumentError('User ID cannot be empty');

    await executeWithRetry(() async {
      await _supabase
          .from(_likesTable)
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
      debugPrint('User $userId unliked the post $postId');
    }, maxRetries: _maxRetries, retryDelay: _retryDelay);
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

  Future<String> _uploadPostVideo(File videoFile, String userId) async {
    try {
      final fileExt = videoFile.path.split('.').last;
      final fileName =
          'video_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName';

      debugPrint('Uploading post video to path: $filePath');

      await _supabase.storage.from(_storageBucket).upload(
            filePath,
            videoFile,
            fileOptions: supabase.FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      final videoUrl =
          _supabase.storage.from(_storageBucket).getPublicUrl(filePath);

      if (videoUrl.isEmpty) {
        throw Exception('Failed to get public URL for uploaded video');
      }

      debugPrint('Post video uploaded successfully. URL: $videoUrl');
      return '$filePath|$videoUrl';
    } on supabase.StorageException catch (e) {
      debugPrint('Storage error uploading post video: [31m${e.message}[0m');
      if (e.message.contains('row-level security policy')) {
        throw Exception(
            'Unable to upload post video. Check your RLS policies and bucket settings.');
      }
      rethrow;
    } catch (e) {
      debugPrint('Error uploading post video: $e');
      rethrow;
    }
  }

  Future<List<PostDataModel>> getFriendsPosts(String userId) async {
    if (userId.isEmpty) throw ArgumentError('User ID cannot be empty');

    return await executeWithRetry(() async {
      // Get list of friend IDs
      final friends = await _supabase
          .from('friends')
          .select('user1_id, user2_id')
          .or('user1_id.eq.$userId,user2_id.eq.$userId');

      // Extract all relevant user IDs (friends + current user)
      final friendIds = friends
          .map<String>(
              (f) => f['user1_id'] == userId ? f['user2_id'] : f['user1_id'])
          .toList();
      friendIds.add(userId); // Include current user's posts

      // Get posts from these users
      final response = await _supabase
          .from(_postsTable)
          .select()
          .inFilter('user_id', friendIds)
          .order('created_at', ascending: false);

      return (response as List).map<PostDataModel>((item) {
        return PostDataModel.fromMap(item, item['id']);
      }).toList();
    }, maxRetries: _maxRetries, retryDelay: _retryDelay);
  }
}
