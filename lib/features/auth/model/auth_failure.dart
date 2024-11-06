import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_failure.freezed.dart';


@freezed
class AuthFailure with _$AuthFailure {
  const factory AuthFailure.serverError() = _ServerError;
  const factory AuthFailure.emailAlreadyInUse() = _EmailAlreadyInUse;
  const factory AuthFailure.usernameAlreadyInUse() = _UsernameAlreadyInUse;
  const factory AuthFailure.invalidEmailAndPasswordCombination() = _InvalidEmailAndPasswordCombination;
  const factory AuthFailure.weakPassword() = _WeakPassword;
  const factory AuthFailure.userNotFound() = _UserNotFound;
  const factory AuthFailure.databaseError(String message) = _DatabaseError;
  const factory AuthFailure.networkError() = _NetworkError;
  const factory AuthFailure.unauthenticated() = _Unauthenticated;
}

extension AuthFailureX on AuthFailure {
  String toErrorMessage() {
    return when(
      serverError: () => 'An unexpected error occurred. Please try again.',
      emailAlreadyInUse: () => 'This email is already registered. Please try a different email.',
      usernameAlreadyInUse: () => 'This username is already taken. Please choose another one.',
      invalidEmailAndPasswordCombination: () => 'Invalid email or password combination.',
      weakPassword: () => 'The password is too weak. Please use a stronger password.',
      userNotFound: () => 'No user found with this email.',
      databaseError: (message) => 'Database error: $message',
      networkError: () => 'A network error occurred. Please check your connection.',
      unauthenticated: () => 'You are not authenticated. Please sign in.',
    );
  }
}