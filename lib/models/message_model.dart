class MessageModel {
  final int? id;
  final int senderId;
  final int receiverId;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  MessageModel({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] as int?,
      senderId: map['sender_id'] as int,
      receiverId: map['receiver_id'] as int,
      message: map['message'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      isRead: map['is_read'] as bool? ?? false,
    );
  }
}
