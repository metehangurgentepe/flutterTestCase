class ChatRoom {
  final String? id;
  final String? name;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final bool isGroup;
  final String? imageUrl;
  final DateTime createdAt;
  final List<String> participants;

  ChatRoom({
    this.id,
    this.name,
    this.lastMessage,
    this.lastMessageTime,
    required this.isGroup,
    this.imageUrl,
    DateTime? createdAt,
    required this.participants,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'],
      name: json['name'],
      lastMessage: json['last_message'],
      lastMessageTime: json['last_message_time'] != null 
          ? DateTime.parse(json['last_message_time'])
          : null,
      isGroup: json['is_group'] ?? false,
      imageUrl: json['image_url'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      participants: (json['participants'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'is_group': isGroup,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'participants': participants,
    };
  }
}