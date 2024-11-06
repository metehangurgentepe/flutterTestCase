import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String username,
    required String email,
    String? fullName,
    String? avatarUrl,
    @Default(false) bool isOnline,
    DateTime? lastSeen,
    DateTime? updatedAt,
    required DateTime createdAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
}

final emptyUserModel = UserModel(
  id: '',
  username: '',
  email: '',
  createdAt: DateTime(0),
);