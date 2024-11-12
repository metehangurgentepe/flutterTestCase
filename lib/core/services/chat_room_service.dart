
import 'package:test_case/features/chat/model/chat_message_model.dart';
import 'package:test_case/features/chat/repository/chat_room_repository.dart';

class ChatRoomService {
  final IChatRoomRepository _repository;

  ChatRoomService(this._repository);

  Stream<List<ChatMessage>> getMessages(String roomId) {
    return _repository.getMessages(roomId);
  }

  Future<void> sendMessage(ChatMessage message) async {
    await _repository.sendMessage(message);
  }

  Future<void> markAsRead(String messageId) async {
    await _repository.markAsRead(messageId);
  }

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    return await _repository.getUserProfile(userId);
  }

  void dispose() {
    // Add any necessary cleanup code here
  }
}