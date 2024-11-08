
class UserPresence {
  final String userId;
  final String status;
  final DateTime? lastSeen;
  final DateTime? onlineAt;

  UserPresence({
    required this.userId,
    required this.status,
    this.lastSeen,
    this.onlineAt,
  });

  factory UserPresence.fromJson(Map<String, dynamic> json) {
    return UserPresence(
      userId: json['user_id'] as String,
      status: json['status'] as String? ?? 'offline',
      lastSeen: json['last_seen'] != null 
          ? DateTime.parse(json['last_seen'] as String) 
          : null,
      onlineAt: json['online_at'] != null 
          ? DateTime.parse(json['online_at'] as String) 
          : null,
    );
  }

  factory UserPresence.offline(String userId) {
    return UserPresence(
      userId: userId,
      status: 'offline',
    );
  }

  bool get isOnline => status == 'online';
}