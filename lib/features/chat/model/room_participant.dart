class RoomParticipant {
  final String roomId;
  final String userId;
  final DateTime joinedAt;

  RoomParticipant({
    required this.roomId,
    required this.userId,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  factory RoomParticipant.fromJson(Map<String, dynamic> json) {
    return RoomParticipant(
      roomId: json['room_id'],
      userId: json['user_id'],
      joinedAt: json['joined_at'] != null 
          ? DateTime.parse(json['joined_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'user_id': userId,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}