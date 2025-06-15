import 'package:timeago/timeago.dart' as timeago;

class CommentModel {
  final String commentId; // Firestore document ID for the comment
  final String userId;
  final String displayName;
  final String profileImageUrl;
  final String commentText;
  final DateTime createdAt;

  CommentModel({
    required this.commentId,
    required this.userId,
    required this.displayName,
    required this.profileImageUrl,
    required this.commentText,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'profile_image_url': profileImageUrl,
      'comment_text': commentText,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map, String commentId) {
    return CommentModel(
      commentId: commentId,
      userId: map['user_id'] as String? ?? '',
      displayName: map['display_name'] as String? ?? 'Anonymous',
      profileImageUrl: map['profile_image_url'] as String? ?? '',
      commentText: map['comment_text'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String get timeAgo => timeago.format(createdAt);
}
