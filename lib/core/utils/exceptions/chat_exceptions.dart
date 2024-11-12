class ChatRoomCreationException implements Exception {
  final String message;
  final dynamic error;
  ChatRoomCreationException(this.message, this.error);
}

class ProfileFetchException implements Exception {
  final String message;
  final dynamic error;
  ProfileFetchException(this.message, this.error);
}

class MessageSendException implements Exception {
  final String message;
  final dynamic error;
  MessageSendException(this.message, this.error);
}