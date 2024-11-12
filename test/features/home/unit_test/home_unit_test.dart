import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test_case/features/auth/model/user_model.dart';
import 'package:test_case/features/home/models/chat_room_model.dart';
import 'package:test_case/features/home/providers/chat_provider.dart';
import 'package:test_case/features/home/providers/notifier/home_notifier.dart';
import 'package:test_case/features/home/repository/chat_repository.dart';
import 'home_unit_test.mocks.dart';


@GenerateMocks([ChatRepository])
void main() {
  late MockChatRepository mockChatRepository;
  late ProviderContainer container;
  
  final testUser = UserModel(
    id: 'test-user-id',
    username: 'testUser',
    email: 'test@example.com',
    createdAt: DateTime.now(),
    role: UserRole.user,
  );

  final testChatRoom = ChatRoom(
    id: '1',
    name: 'Test Chat',
    isGroup: false,
    participants: ['test-user-id', 'other-user'],
    createdAt: DateTime.now(),
  );

  final testGroupRoom = ChatRoom(
    id: '2',
    name: 'Test Group',
    isGroup: true,
    participants: ['test-user-id', 'user1', 'user2'],
    createdAt: DateTime.now(),
  );

  setUp(() {
    mockChatRepository = MockChatRepository();
    container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(mockChatRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('HomeNotifier Tests -', () {
    test('should create chat room successfully', () async {
      when(mockChatRepository.createChatRoom(any))
          .thenAnswer((_) async => testChatRoom);

      final notifier = HomeNotifier(mockChatRepository);
      final result = await notifier.createChatRoom(testChatRoom);

      expect(result.id, equals(testChatRoom.id));
      expect(result.name, equals(testChatRoom.name));
      expect(result.isGroup, equals(testChatRoom.isGroup));
      verify(mockChatRepository.createChatRoom(testChatRoom)).called(1);
    });

    test('should handle chat room creation error', () async {
      when(mockChatRepository.createChatRoom(any))
          .thenThrow(Exception('Failed to create chat room'));

      final notifier = HomeNotifier(mockChatRepository);

      expect(
        () => notifier.createChatRoom(testChatRoom),
        throwsException,
      );
      verify(mockChatRepository.createChatRoom(testChatRoom)).called(1);
    });

    test('should create group room successfully', () async {
      when(mockChatRepository.createChatRoom(any))
          .thenAnswer((_) async => testGroupRoom);

      final notifier = HomeNotifier(mockChatRepository);
      await notifier.createGroupRoom(
        testGroupRoom.name ?? '',
        testGroupRoom.participants,
      );

      verify(mockChatRepository.createChatRoom(any)).called(1);
      expect(notifier.state, equals(const AsyncValue<void>.data(null)));
    });

    test('should handle group room creation error', () async {
      when(mockChatRepository.createChatRoom(any))
          .thenThrow(Exception('Failed to create group'));

      final notifier = HomeNotifier(mockChatRepository);
      
      await expectLater(
        () => notifier.createGroupRoom(
          testGroupRoom.name ?? '',
          testGroupRoom.participants,
        ),
        throwsException,
      );

      verify(mockChatRepository.createChatRoom(any)).called(1);
      expect(notifier.state, isA<AsyncError>());
    });
  });

  group('Group Rooms Provider Tests -', () {
    test('should load group rooms successfully', () async {
      final controller = StreamController<List<ChatRoom>>();
      when(mockChatRepository.getGroupRooms(any))
          .thenAnswer((_) => controller.stream);
      
      final completer = Completer<void>();

      container.listen<AsyncValue<List<ChatRoom>>>(
        groupRoomsProvider(testUser.id),
        (previous, next) {
          if (next case AsyncData(:final value)) {
            expect(value.first.id, equals(testGroupRoom.id));
            if (!completer.isCompleted) completer.complete();
          }
        },
        fireImmediately: true,
      );

      controller.add([testGroupRoom]);
      await completer.future.timeout(const Duration(seconds: 1));
      await controller.close();
    });

    test('should handle empty group rooms', () async {
      final controller = StreamController<List<ChatRoom>>();
      when(mockChatRepository.getGroupRooms(any))
          .thenAnswer((_) => controller.stream);
      
      final completer = Completer<void>();

      container.listen<AsyncValue<List<ChatRoom>>>(
        groupRoomsProvider(testUser.id),
        (previous, next) {
          if (next case AsyncData(:final value)) {
            expect(value.isEmpty, isTrue);
            if (!completer.isCompleted) completer.complete();
          }
        },
        fireImmediately: true,
      );

      controller.add([]);
      await completer.future.timeout(const Duration(seconds: 1));
      await controller.close();
    });

    test('should handle group rooms error', () async {
      final controller = StreamController<List<ChatRoom>>();
      when(mockChatRepository.getGroupRooms(any))
          .thenAnswer((_) => controller.stream);
      
      final completer = Completer<void>();

      container.listen<AsyncValue<List<ChatRoom>>>(
        groupRoomsProvider(testUser.id),
        (previous, next) {
          if (next case AsyncError()) {
            if (!completer.isCompleted) completer.complete();
          }
        },
        fireImmediately: true,
      );

      controller.addError('Error loading groups');
      await completer.future.timeout(const Duration(seconds: 1));
      await controller.close();
    });
  });

  group('Provider State Tests -', () {
    test('chatListProvider should initialize with data null state', () {
      final initialState = container.read(chatListProvider);
      expect(initialState, equals(const AsyncValue<void>.data(null)));
    });

    test('groupRoomsProvider should start with loading state', () {
      when(mockChatRepository.getGroupRooms(any))
          .thenAnswer((_) => const Stream.empty());

      final initialState = container.read(groupRoomsProvider(testUser.id));
      expect(initialState, const AsyncValue<List<ChatRoom>>.loading());
    });
  });
}