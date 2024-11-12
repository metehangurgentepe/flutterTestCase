import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test_case/features/auth/model/user_model.dart';
import 'package:test_case/features/auth/notifiers/auth_notifier.dart';
import 'package:test_case/features/auth/providers/providers.dart';
import 'package:test_case/features/home/models/chat_room_model.dart';
import 'package:test_case/features/home/providers/chat_provider.dart';
import 'package:test_case/features/home/repository/chat_repository.dart';
import 'package:test_case/core/services/auth_service.dart';
import 'package:test_case/features/home/view/home_view.dart';

import 'home_view_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ChatRepository>(),
  MockSpec<IAuthService>(),
  MockSpec<NavigatorObserver>(),
])
void main() {
  late MockChatRepository mockChatRepository;
  late MockIAuthService mockAuthService;
  late MockNavigatorObserver mockNavigatorObserver;
  late ProviderContainer container;

  final testUser = UserModel(
    id: 'test-user-id',
    username: 'testUser',
    email: 'test@example.com',
    createdAt: DateTime.now(),
    role: UserRole.user,
  );

  final testPersonalChats = [
    ChatRoom(
      id: '1',
      name: 'Personal Chat 1',
      isGroup: false,
      participants: ['test-user-id', 'other-user'],
      createdAt: DateTime.now(),
      lastMessage: 'Last message 1',
      lastMessageTime: DateTime.now(),
    ),
    ChatRoom(
      id: '2',
      name: 'Personal Chat 2',
      isGroup: false,
      participants: ['test-user-id', 'another-user'],
      createdAt: DateTime.now(),
      lastMessage: 'Last message 2',
      lastMessageTime: DateTime.now(),
    ),
  ];

  final testGroupChats = [
    ChatRoom(
      id: '3',
      name: 'Group Chat 1',
      isGroup: true,
      participants: ['test-user-id', 'user1', 'user2'],
      createdAt: DateTime.now(),
      lastMessage: 'Last group message 1',
      lastMessageTime: DateTime.now(),
    ),
    ChatRoom(
      id: '4',
      name: 'Group Chat 2',
      isGroup: true,
      participants: ['test-user-id', 'user3', 'user4'],
      createdAt: DateTime.now(),
      lastMessage: 'Last group message 2',
      lastMessageTime: DateTime.now(),
    ),
  ];

  setUp(() {
    mockChatRepository = MockChatRepository();
    mockAuthService = MockIAuthService();
    mockNavigatorObserver = MockNavigatorObserver();

    when(mockAuthService.currentUser).thenReturn(testUser);
    when(mockAuthService.authStateChanges())
        .thenAnswer((_) => Stream.value(testUser));
    when(mockAuthService.signOut()).thenAnswer((_) async => null);

    when(mockChatRepository.getChatRooms(any))
        .thenAnswer((_) => Stream.value(testPersonalChats));
    when(mockChatRepository.getGroupRooms(any))
        .thenAnswer((_) => Stream.value(testGroupChats));

    container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(mockChatRepository),
        authServiceProvider.overrideWithValue(mockAuthService),
        authStateProvider.overrideWith(
          (ref) => AuthNotifier(mockAuthService),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  Widget createTestWidget() {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        navigatorObservers: [mockNavigatorObserver],
        home: const HomeView(),
      ),
    );
  }

  group('HomeView Tests -', () {
    testWidgets('shows personal chats in Chats tab', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Personal Chat 1'), findsOneWidget);
      expect(find.text('Personal Chat 2'), findsOneWidget);
    });

    testWidgets('shows group chats in Groups tab', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Groups'));
      await tester.pumpAndSettle();

      expect(find.text('Group Chat 1'), findsOneWidget);
      expect(find.text('Group Chat 2'), findsOneWidget);
    });

    testWidgets('shows empty state when no personal chats', (tester) async {
      when(mockChatRepository.getChatRooms(any))
          .thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('No chats yet'), findsOneWidget);
    });

    testWidgets('shows empty state when no group chats', (tester) async {
      when(mockChatRepository.getGroupRooms(any))
          .thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Groups'));
      await tester.pumpAndSettle();

      expect(find.text('No group chats yet'), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      when(mockChatRepository.getChatRooms(any))
          .thenAnswer((_) => Stream.empty());

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state', (tester) async {
      when(mockChatRepository.getChatRooms(any))
          .thenAnswer((_) => Stream.error('Error loading chats'));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Error: Error loading chats'), findsOneWidget);
    });

    testWidgets('logout dialog and functionality works', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      expect(find.text('Logout'), findsOneWidget);
      expect(find.text('Are you sure you want to logout?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      verifyNever(mockAuthService.signOut());

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      verify(mockAuthService.signOut()).called(1);
    });
  });
}