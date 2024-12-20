// Mocks generated by Mockito 5.4.4 from annotations
// in test_case/test/features/home/unit_test/home_unit_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;

import 'package:mockito/mockito.dart' as _i1;
import 'package:test_case/features/auth/model/user_model.dart' as _i5;
import 'package:test_case/features/home/models/chat_room_model.dart' as _i2;
import 'package:test_case/features/home/repository/chat_repository.dart' as _i3;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeChatRoom_0 extends _i1.SmartFake implements _i2.ChatRoom {
  _FakeChatRoom_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [ChatRepository].
///
/// See the documentation for Mockito's code generation for more information.
class MockChatRepository extends _i1.Mock implements _i3.ChatRepository {
  MockChatRepository() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.Stream<List<_i2.ChatRoom>> getChatRoomsStream(String? userId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getChatRoomsStream,
          [userId],
        ),
        returnValue: _i4.Stream<List<_i2.ChatRoom>>.empty(),
      ) as _i4.Stream<List<_i2.ChatRoom>>);

  @override
  _i4.Future<_i2.ChatRoom> createChatRoom(_i2.ChatRoom? room) =>
      (super.noSuchMethod(
        Invocation.method(
          #createChatRoom,
          [room],
        ),
        returnValue: _i4.Future<_i2.ChatRoom>.value(_FakeChatRoom_0(
          this,
          Invocation.method(
            #createChatRoom,
            [room],
          ),
        )),
      ) as _i4.Future<_i2.ChatRoom>);

  @override
  _i4.Stream<List<_i2.ChatRoom>> getChatRooms(String? userId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getChatRooms,
          [userId],
        ),
        returnValue: _i4.Stream<List<_i2.ChatRoom>>.empty(),
      ) as _i4.Stream<List<_i2.ChatRoom>>);

  @override
  _i4.Stream<List<_i2.ChatRoom>> getGroupRooms(String? userId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getGroupRooms,
          [userId],
        ),
        returnValue: _i4.Stream<List<_i2.ChatRoom>>.empty(),
      ) as _i4.Stream<List<_i2.ChatRoom>>);

  @override
  _i4.Future<_i2.ChatRoom?> findExistingChatRoom(
    String? user1Id,
    String? user2Id,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #findExistingChatRoom,
          [
            user1Id,
            user2Id,
          ],
        ),
        returnValue: _i4.Future<_i2.ChatRoom?>.value(),
      ) as _i4.Future<_i2.ChatRoom?>);

  @override
  _i4.Stream<List<_i5.UserModel>> getUsers(String? searchQuery) =>
      (super.noSuchMethod(
        Invocation.method(
          #getUsers,
          [searchQuery],
        ),
        returnValue: _i4.Stream<List<_i5.UserModel>>.empty(),
      ) as _i4.Stream<List<_i5.UserModel>>);

  @override
  void clearCache() => super.noSuchMethod(
        Invocation.method(
          #clearCache,
          [],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void dispose() => super.noSuchMethod(
        Invocation.method(
          #dispose,
          [],
        ),
        returnValueForMissingStub: null,
      );
}
