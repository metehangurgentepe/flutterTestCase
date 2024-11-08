// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockito/mockito.dart';
// import 'package:mockito/annotations.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:test_case/core/utils/helpers/cache_manager.dart';
// import 'package:test_case/features/auth/model/user_model.dart';
// import 'package:test_case/features/chat/model/chat_message_model.dart';
// import 'package:test_case/features/chat/model/chat_room_model.dart';
// import 'package:test_case/features/chat/repository/chat_repository.dart';

// import 'chat_repository_test.mocks.dart'; // Add this import

// @GenerateMocks([
//   SupabaseClient, 
//   SupabaseQueryBuilder, 
//   CacheManager, 
//   RealtimeChannel,
//   SupabaseStreamFilterBuilder,
// ])
// void main() {
//   late ChatRepository chatRepository;
//   late MockSupabaseClient mockSupabase;
//   late MockCacheManager mockCache;
//   late MockSupabaseQueryBuilder mockQueryBuilder;
//   late MockSupabaseStreamFilterBuilder mockStreamBuilder;

//   setUp(() {
//     mockSupabase = MockSupabaseClient();
//     mockCache = MockCacheManager();
//     mockQueryBuilder = MockSupabaseQueryBuilder();
//     mockStreamBuilder = MockSupabaseStreamFilterBuilder();
//     chatRepository = ChatRepository(mockSupabase);
//   });

//   group('ChatRepository Tests', () {
//     final testUserId = 'test-user-id';
//     final testRoomId = 'test-room-id';

//     group('getChatRooms', () {
//       test('should return cached rooms if available', () {
//         // Arrange
//         final cachedRooms = [
//           ChatRoom(
//             id: '1',
//             name: 'Test Room',
//             isGroup: false,
//             participants: ['user1', 'user2'],
//             createdAt: DateTime.now(),
//           )
//         ];

//         when(mockCache.hasValid('rooms_$testUserId')).thenReturn(true);
//         when(mockCache.get<List<ChatRoom>>('rooms_$testUserId'))
//             .thenReturn(cachedRooms);

//         // Act
//         final result = chatRepository.getChatRooms(testUserId);

//         // Assert
//         expect(result, emits(cachedRooms));
//       });

//       test('should fetch and cache rooms when cache is invalid', () async {
//         // Arrange
//         final roomData = [
//           {
//             'id': '1',
//             'participants': ['user1', 'user2'],
//             'created_at': DateTime.now().toIso8601String(),
//             'is_group': false,
//             'last_message': null,
//             'last_message_time': null,
//           }
//         ];

//         final userProfile = {
//           'username': 'Test User',
//           'avatar_url': 'test_url'
//         };

//         when(mockCache.hasValid('rooms_$testUserId')).thenReturn(false);
//         when(mockSupabase.from('chat_rooms')).thenReturn(mockQueryBuilder);
        
//         // Setup stream builder with SupabaseStreamFilterBuilder
//         when(mockQueryBuilder.stream(primaryKey: ['id'])).thenAnswer((_) {
//           return SupabaseStreamFilterBuilder(
//             queryBuilder: mockQueryBuilder,
//             primaryKey: ['id'],
//             realtimeTopic: 'realtime:*',
//           )..stream = Stream.value(
//               PostgrestResponse<List<Map<String, dynamic>>>(
//                 data: roomData,
//                 status: 200,
//                 count: null,
//               ),
//             );
//         });
                
//         // PostgrestResponse for profiles
//         when(mockSupabase.from('profiles').select())
//             .thenAnswer((_) async => PostgrestResponse(
//                   data: [userProfile],
//                   status: 200,
//                   count: null,
//                 ));

//         // Act
//         final stream = chatRepository.getChatRooms(testUserId);

//         // Assert
//         await expectLater(
//           stream,
//           emits(isA<List<ChatRoom>>()),
//         );
//       });
//     });

//     group('getMessages', () {
//       test('should return messages stream', () async {
//         // Arrange
//         final mockChannel = MockRealtimeChannel();
//         final messageData = [
//           {
//             'id': '1',
//             'content': 'Test message',
//             'sender_id': testUserId,
//             'room_id': testRoomId,
//             'created_at': DateTime.now().toIso8601String(),
//             'is_read': false,
//           }
//         ];

//         when(mockSupabase.channel(any)).thenReturn(mockChannel);
//         when(mockChannel.onPostgresChanges(
//           event: any,
//           schema: any,
//           table: any,
//           filter: any,
//           callback: any,
//         )).thenReturn(mockChannel);
//         when(mockChannel.subscribe()).thenReturn(mockChannel);

//         when(mockSupabase.from('messages')).thenReturn(mockQueryBuilder);
        
//         // Setup stream builder with SupabaseStreamFilterBuilder
//         when(mockQueryBuilder.stream(primaryKey: ['id'])).thenAnswer((_) {
//           return SupabaseStreamFilterBuilder(
//             queryBuilder: mockQueryBuilder,
//             primaryKey: ['id'],
//             realtimeTopic: 'realtime:*',
//           )..stream = Stream.value(
//               PostgrestResponse<List<Map<String, dynamic>>>(
//                 data: messageData,
//                 status: 200,
//                 count: null,
//               ),
//             );
//         });

//         // Act
//         final stream = chatRepository.getMessages(testRoomId);

//         // Assert
//         await expectLater(
//           stream,
//           emits(isA<List<ChatMessage>>()),
//         );
//       });
//     });

//     group('sendMessage', () {
//       test('should send message and update chat room', () async {
//         // Arrange
//         final testMessage = ChatMessage(
//           id: 1,
//           content: 'Test message',
//           senderId: testUserId,
//           roomId: testRoomId,
//           createdAt: DateTime.now(),
//         );

//         when(mockSupabase.from('messages')).thenReturn(mockQueryBuilder);
//         when(mockSupabase.from('chat_rooms')).thenReturn(mockQueryBuilder);
        
//         when(mockQueryBuilder.insert(any)).thenAnswer((_) async => PostgrestResponse(
//               data: [{}],
//               status: 200,
//               count: null,
//             ));
            
//         when(mockQueryBuilder.update(any)).thenAnswer((_) async => PostgrestResponse(
//               data: [{}],
//               status: 200,
//               count: null,
//             ));
            
//         when(mockQueryBuilder.select()).thenAnswer(
//           (_) async => PostgrestResponse(
//             data: [{
//               'is_group': false,
//               'participants': [testUserId, 'other-user-id']
//             }],
//             status: 200,
//             count: null,
//           ),
//         );

//         // Act & Assert
//         expect(
//           () => chatRepository.sendMessage(testMessage),
//           completion(isNull),
//         );
//       });
//     });
//   });
// }
