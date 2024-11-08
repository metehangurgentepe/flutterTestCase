class ChatException implements Exception {
  final String message;
  final dynamic originalError;

  ChatException(this.message, [this.originalError]);

  @override
  String toString() => 'ChatException: $message${originalError != null ? ' ($originalError)' : ''}';
}

class ChatRoomCreationException extends ChatException {
  ChatRoomCreationException(String message, [dynamic originalError]) 
    : super(message, originalError);
}

class MessageSendException extends ChatException {
  MessageSendException(String message, [dynamic originalError]) 
    : super(message, originalError);
}

class ProfileFetchException extends ChatException {
  ProfileFetchException(String message, [dynamic originalError]) 
    : super(message, originalError);
} 