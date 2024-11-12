// Mocks generated by Mockito 5.4.4 from annotations
// in test_case/test/features/home/widget_test/home_view_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;

import 'package:flutter/src/widgets/navigator.dart' as _i8;
import 'package:mockito/mockito.dart' as _i1;
import 'package:test_case/core/services/auth_service.dart' as _i6;
import 'package:test_case/features/auth/model/auth_failure.dart' as _i7;
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
  @override
  _i4.Stream<List<_i2.ChatRoom>> getChatRoomsStream(String? userId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getChatRoomsStream,
          [userId],
        ),
        returnValue: _i4.Stream<List<_i2.ChatRoom>>.empty(),
        returnValueForMissingStub: _i4.Stream<List<_i2.ChatRoom>>.empty(),
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
        returnValueForMissingStub:
            _i4.Future<_i2.ChatRoom>.value(_FakeChatRoom_0(
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
        returnValueForMissingStub: _i4.Stream<List<_i2.ChatRoom>>.empty(),
      ) as _i4.Stream<List<_i2.ChatRoom>>);

  @override
  _i4.Stream<List<_i2.ChatRoom>> getGroupRooms(String? userId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getGroupRooms,
          [userId],
        ),
        returnValue: _i4.Stream<List<_i2.ChatRoom>>.empty(),
        returnValueForMissingStub: _i4.Stream<List<_i2.ChatRoom>>.empty(),
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
        returnValueForMissingStub: _i4.Future<_i2.ChatRoom?>.value(),
      ) as _i4.Future<_i2.ChatRoom?>);

  @override
  _i4.Stream<List<_i5.UserModel>> getUsers(String? searchQuery) =>
      (super.noSuchMethod(
        Invocation.method(
          #getUsers,
          [searchQuery],
        ),
        returnValue: _i4.Stream<List<_i5.UserModel>>.empty(),
        returnValueForMissingStub: _i4.Stream<List<_i5.UserModel>>.empty(),
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

/// A class which mocks [IAuthService].
///
/// See the documentation for Mockito's code generation for more information.
class MockIAuthService extends _i1.Mock implements _i6.IAuthService {
  @override
  _i4.Future<_i7.AuthFailure?> signIn({
    required String? email,
    required String? password,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #signIn,
          [],
          {
            #email: email,
            #password: password,
          },
        ),
        returnValue: _i4.Future<_i7.AuthFailure?>.value(),
        returnValueForMissingStub: _i4.Future<_i7.AuthFailure?>.value(),
      ) as _i4.Future<_i7.AuthFailure?>);

  @override
  _i4.Future<_i7.AuthFailure?> signUp({
    required String? email,
    required String? password,
    required String? username,
    required _i5.UserRole? role,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #signUp,
          [],
          {
            #email: email,
            #password: password,
            #username: username,
            #role: role,
          },
        ),
        returnValue: _i4.Future<_i7.AuthFailure?>.value(),
        returnValueForMissingStub: _i4.Future<_i7.AuthFailure?>.value(),
      ) as _i4.Future<_i7.AuthFailure?>);

  @override
  _i4.Future<_i7.AuthFailure?> signOut() => (super.noSuchMethod(
        Invocation.method(
          #signOut,
          [],
        ),
        returnValue: _i4.Future<_i7.AuthFailure?>.value(),
        returnValueForMissingStub: _i4.Future<_i7.AuthFailure?>.value(),
      ) as _i4.Future<_i7.AuthFailure?>);

  @override
  _i4.Stream<_i5.UserModel?> authStateChanges() => (super.noSuchMethod(
        Invocation.method(
          #authStateChanges,
          [],
        ),
        returnValue: _i4.Stream<_i5.UserModel?>.empty(),
        returnValueForMissingStub: _i4.Stream<_i5.UserModel?>.empty(),
      ) as _i4.Stream<_i5.UserModel?>);
}

/// A class which mocks [NavigatorObserver].
///
/// See the documentation for Mockito's code generation for more information.
class MockNavigatorObserver extends _i1.Mock implements _i8.NavigatorObserver {
  @override
  void didPush(
    _i8.Route<dynamic>? route,
    _i8.Route<dynamic>? previousRoute,
  ) =>
      super.noSuchMethod(
        Invocation.method(
          #didPush,
          [
            route,
            previousRoute,
          ],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void didPop(
    _i8.Route<dynamic>? route,
    _i8.Route<dynamic>? previousRoute,
  ) =>
      super.noSuchMethod(
        Invocation.method(
          #didPop,
          [
            route,
            previousRoute,
          ],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void didRemove(
    _i8.Route<dynamic>? route,
    _i8.Route<dynamic>? previousRoute,
  ) =>
      super.noSuchMethod(
        Invocation.method(
          #didRemove,
          [
            route,
            previousRoute,
          ],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void didReplace({
    _i8.Route<dynamic>? newRoute,
    _i8.Route<dynamic>? oldRoute,
  }) =>
      super.noSuchMethod(
        Invocation.method(
          #didReplace,
          [],
          {
            #newRoute: newRoute,
            #oldRoute: oldRoute,
          },
        ),
        returnValueForMissingStub: null,
      );

  @override
  void didStartUserGesture(
    _i8.Route<dynamic>? route,
    _i8.Route<dynamic>? previousRoute,
  ) =>
      super.noSuchMethod(
        Invocation.method(
          #didStartUserGesture,
          [
            route,
            previousRoute,
          ],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void didStopUserGesture() => super.noSuchMethod(
        Invocation.method(
          #didStopUserGesture,
          [],
        ),
        returnValueForMissingStub: null,
      );
}
