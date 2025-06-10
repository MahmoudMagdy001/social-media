class CommentModel {
  final String commentId; // Firestore document ID for the comment
  final String userId;
  final String username;
  final String profileImageUrl;
  final String commentText;
  final DateTime timestamp;

  CommentModel({
    required this.commentId,
    required this.userId,
    required this.username,
    required this.profileImageUrl,
    required this.commentText,
    required this.timestamp,
  });

  // Not sending commentId to Firestore as it's the document's ID
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'username': username,
      'profile_image_url': profileImageUrl,
      'comment_text': commentText,
      'created_at': timestamp.toIso8601String(),
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map, String commentId) {
    return CommentModel(
      commentId: commentId,
      userId: map['user_id'] as String? ?? '',
      username: map['username'] as String? ?? 'Anonymous',
      profileImageUrl: map['profile_image_url'] as String? ?? '',
      commentText: map['comment_text'] as String? ?? '',
      timestamp: DateTime.parse(map['created_at'] as String),
    );
  }
}
