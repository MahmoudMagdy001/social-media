// If you have a separate CommentsModel for structure, it's fine, but it won't be a direct field anymore.

class PostDataModel {
  final String postId;
  final String username;
  final String profileImageUrl;
  final String postText;
  final DateTime postTime;
  final int sharesCount;
  final String userId;
  final String documentId;
  final String? postImageUrl;

  PostDataModel({
    required this.postId,
    required this.username,
    required this.profileImageUrl,
    required this.postText,
    required this.postTime,
    required this.sharesCount,
    required this.userId,
    required this.documentId,
    this.postImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': postId,
      'username': username,
      'profile_image_url': profileImageUrl,
      'post_text': postText,
      'created_at': postTime.toIso8601String(),
      'shares_count': sharesCount,
      'user_id': userId,
      'post_image_url': postImageUrl,
    };
  }

  factory PostDataModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PostDataModel(
      postId: map['id'] as String,
      username: map['username'] as String? ?? 'Anonymous',
      profileImageUrl: map['profile_image_url'] as String? ?? '',
      postText: map['post_text'] as String? ?? '',
      postTime: DateTime.parse(map['created_at'] as String),
      sharesCount: map['shares_count'] as int? ?? 0,
      userId: map['user_id'] as String? ?? '',
      documentId: documentId,
      postImageUrl: map['post_image_url'] as String?,
    );
  }
}
