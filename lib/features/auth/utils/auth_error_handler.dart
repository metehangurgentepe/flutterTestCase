import 'package:flutter/material.dart';
import 'package:test_case/features/auth/model/auth_failure.dart';

class AuthErrorHandler {
  static void showError(BuildContext context, dynamic error) {
    final message = error is AuthFailure 
        ? error.toErrorMessage() 
        : 'An unexpected error occurred';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}