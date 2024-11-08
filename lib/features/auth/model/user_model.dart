// lib/features/auth/model/user_model.dart

enum UserRole {
  admin,
  moderator,
  premiumUser,
  user
}

class UserModel {
  final String id;
  final String username;
  final String email;
  final DateTime createdAt;
  final UserRole role;
  final int messageLimit;
  final bool canCreateGroup;
  final bool isVerified;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime? updatedAt;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.createdAt,
    this.role = UserRole.user,
    this.messageLimit = 100,
    this.canCreateGroup = false,
    this.isVerified = false,
    this.isOnline = false,
    this.lastSeen,
    this.updatedAt,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      role: _roleFromString(json['role'] as String?),
      messageLimit: json['message_limit'] as int? ?? 100,
      canCreateGroup: json['can_create_group'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeen: json['last_seen'] != null 
          ? DateTime.parse(json['last_seen'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'role': _roleToString(role),
      'message_limit': messageLimit,
      'can_create_group': canCreateGroup,
      'is_verified': isVerified,
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'avatar_url': avatarUrl,
    };
  }

  static UserRole _roleFromString(String? role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'moderator':
        return UserRole.moderator;
      case 'premium_user':
        return UserRole.premiumUser;
      default:
        return UserRole.user;
    }
  }

  static String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.moderator:
        return 'moderator';
      case UserRole.premiumUser:
        return 'premium_user';
      case UserRole.user:
        return 'user';
    }
  }

  // Eşitlik kontrolü için override
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.username == username &&
        other.email == email &&
        other.createdAt == createdAt &&
        other.role == role &&
        other.messageLimit == messageLimit &&
        other.canCreateGroup == canCreateGroup &&
        other.isVerified == isVerified &&
        other.isOnline == isOnline &&
        other.lastSeen == lastSeen &&
        other.updatedAt == updatedAt &&
        other.avatarUrl == avatarUrl;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      username,
      email,
      createdAt,
      role,
      messageLimit,
      canCreateGroup,
      isVerified,
      isOnline,
      lastSeen,
      updatedAt,
      avatarUrl,
    );
  }

  // Deep copy için
  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    DateTime? createdAt,
    UserRole? role,
    int? messageLimit,
    bool? canCreateGroup,
    bool? isVerified,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? updatedAt,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
      messageLimit: messageLimit ?? this.messageLimit,
      canCreateGroup: canCreateGroup ?? this.canCreateGroup,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      updatedAt: updatedAt ?? this.updatedAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, email: $email, role: $role, isOnline: $isOnline)';
  }
}