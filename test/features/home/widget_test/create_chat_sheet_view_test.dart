import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:test_case/features/auth/model/user_model.dart';
import 'package:test_case/features/auth/notifiers/auth_notifier.dart';
import 'package:test_case/features/home/repository/chat_repository.dart';
import 'package:test_case/features/auth/providers/providers.dart';
import 'package:test_case/features/home/providers/chat_provider.dart';
import 'package:test_case/core/services/auth_service.dart';
import 'package:test_case/features/home/view/create_chat_sheet_view.dart';

import 'create_chat_sheet_view_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ChatRepository>(),
  MockSpec<IAuthService>(),
])
void main() {
  late MockChatRepository mockChatRepository;
  late MockIAuthService mockAuthService;
  late ProviderContainer container;

  final testCurrentUser = UserModel(
    id: 'current-user-id',
    username: 'currentUser',
    email: 'current@test.com',
    createdAt: DateTime.now(),
    role: UserRole.user,
  );

  final testUsers = [
    UserModel(
      id: 'user1',
      username: 'testUser1',
      email: 'test1@test.com',
      createdAt: DateTime.now(),
      role: UserRole.user,
    ),
    UserModel(
      id: 'user2',
      username: 'testUser2',
      email: 'test2@test.com',
      createdAt: DateTime.now(),
      role: UserRole.user,
    ),
  ];

  setUp(() {
    mockChatRepository = MockChatRepository();
    mockAuthService = MockIAuthService();

    // Setup auth service mock behavior
    when(mockAuthService.currentUser).thenReturn(testCurrentUser);
    when(mockAuthService.authStateChanges())
        .thenAnswer((_) => Stream.value(testCurrentUser));

    // Setup chat repository mock behavior
    when(mockChatRepository.getUsers(any))
        .thenAnswer((_) => Stream.value(testUsers));
    when(mockChatRepository.currentUserId).thenReturn('current-user-id');

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
    return MaterialApp(
      home: Scaffold(
        body: ProviderScope(
          parent: container,
          child: const CreateChatSheet(),
        ),
      ),
    );
  }

  group('CreateChatSheet Widget Tests', () {
    testWidgets('should show search field and user list',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search users...'), findsOneWidget);
      expect(find.text('testUser1'), findsOneWidget);
      expect(find.text('testUser2'), findsOneWidget);
    });

    testWidgets('should filter users when searching',
        (WidgetTester tester) async {
      when(mockChatRepository.getUsers('test1'))
          .thenAnswer((_) => Stream.value([testUsers[0]]));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'test1');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('testUser1'), findsOneWidget);
      expect(find.text('testUser2'), findsNothing);
    });

    testWidgets('should show empty state when no users found',
        (WidgetTester tester) async {
      when(mockChatRepository.getUsers(any))
          .thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No users found'), findsOneWidget);
      expect(find.byIcon(Icons.person_search), findsOneWidget);
    });

    testWidgets('should show loading state initially',
        (WidgetTester tester) async {
      when(mockChatRepository.getUsers(any)).thenAnswer((_) => Stream.empty());

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error state when loading fails',
        (WidgetTester tester) async {
      when(mockChatRepository.getUsers(any))
          .thenAnswer((_) => Stream.error('Failed to load users'));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error: Failed to load users'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
