import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class ChatMessage {
  final int? id;
  
  @JsonKey(name: 'user_id')
  final String senderId;
  
  final String content;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'room_id')
  final String roomId;

  ChatMessage({
    this.id,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.roomId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] != null ? int.parse(json['id'].toString()) : null,
      senderId: json['user_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      roomId: json['room_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'user_id': senderId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'room_id': roomId,
    };
    
    // Only include id if it's not null
    if (id != null) {
      map['id'] = id.toString();
    }
    
    return map;
  }

  @override
  String toString() => 'ChatMessage(id: $id, content: $content)';
}