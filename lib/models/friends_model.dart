class FriendRequestModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderImage;
  final String receiverId;
  final String receiverName;
  final String receiverImage;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FriendRequestModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderImage,
    required this.receiverId,
    required this.receiverName,
    required this.receiverImage,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory FriendRequestModel.fromMap(Map<String, dynamic> map) {
    return FriendRequestModel(
      id: map['id'] ?? '',
      senderId: map['sender_id'] ?? '',
      senderName: map['sender_name'] ?? '',
      senderImage: map['sender_image'] ?? '',
      receiverId: map['receiver_id'] ?? '',
      receiverName: map['receiver_name'] ?? '',
      receiverImage: map['receiver_image'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_image': senderImage,
      'receiver_id': receiverId,
      'receiver_name': receiverName,
      'receiver_image': receiverImage,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
