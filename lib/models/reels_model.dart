class ReelModel {
  final String id;
  final String userId;
  final String displayName;
  final String profileImageUrl;
  final String postText;
  final String postVideoUrl;
  final DateTime createdAt;

  ReelModel({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.profileImageUrl,
    required this.postText,
    required this.postVideoUrl,
    required this.createdAt,
  });

  factory ReelModel.fromMap(Map<String, dynamic> map) {
    return ReelModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      displayName: map['display_name'] ?? '',
      profileImageUrl: map['profile_image_url'] ?? '',
      postText: map['post_text'] ?? '',
      postVideoUrl: map['post_video_url'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
