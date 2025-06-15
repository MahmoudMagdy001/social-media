import 'package:timeago/timeago.dart' as timeago;

class PostDataModel {
  final String postId;
  final String displayName;
  final String profileImageUrl;
  final String postText;
  final DateTime postTime;
  final int sharesCount;
  final String userId;
  final String documentId;
  final String? postImageUrl;
  final String? postVideoUrl;

  PostDataModel({
    required this.postId,
    required this.displayName,
    required this.profileImageUrl,
    required this.postText,
    required this.postTime,
    required this.sharesCount,
    required this.userId,
    required this.documentId,
    this.postImageUrl,
    this.postVideoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': postId,
      'display_name': displayName,
      'profile_image_url': profileImageUrl,
      'post_text': postText,
      'created_at': postTime.toIso8601String(),
      'shares_count': sharesCount,
      'user_id': userId,
      'post_image_url': postImageUrl,
      'post_video_url': postVideoUrl,
    };
  }

  factory PostDataModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PostDataModel(
      postId: map['id'] as String,
      displayName: map['display_name'] as String? ?? 'Anonymous',
      profileImageUrl: map['profile_image_url'] as String? ?? '',
      postText: map['post_text'] as String? ?? '',
      postTime: DateTime.parse(map['created_at'] as String),
      sharesCount: map['shares_count'] as int? ?? 0,
      userId: map['user_id'] as String? ?? '',
      documentId: documentId,
      postImageUrl: map['post_image_url'] as String?,
      postVideoUrl: map['post_video_url'] as String?,
    );
  }

  String get timeAgo => timeago.format(postTime);
}
