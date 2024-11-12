import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/features/auth/providers/providers.dart';
import 'package:test_case/features/auth/utils/auth_error_handler.dart';
import 'package:test_case/features/auth/view/register_view.dart';
import 'package:test_case/features/auth/widgets/auth_button.dart';
import 'package:test_case/features/auth/widgets/auth_text_field.dart';
import 'package:test_case/features/auth/utils/auth_form_validator.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    final result = await ref.read(authStateProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
    if (mounted && result != null) {
      AuthErrorHandler.showError(context, result);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: authState.when(
        data: (_) => _buildLoginForm(),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => _handleError(error),
      ),
    );
  }

  Widget _handleError(dynamic error) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AuthErrorHandler.showError(context, error);
      }
    });
    return _buildLoginForm();
  }

  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AuthTextField(
              controller: _emailController,
              labelText: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: AuthFormValidator.validateEmail,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _passwordController,
              labelText: 'Password',
              isPassword: true,
              validator: AuthFormValidator.validatePassword,
            ),
            const SizedBox(height: 24),
            AuthButton(
              onPressed: _handleSubmit,
              text: 'Login',
              isLoading: ref.watch(authStateProvider).isLoading,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterView(),
                  ),
                );
              },
              child: const Text("Don't have an account? Register"),
            ),
          ],
        ),
      ),
    );
  }
}
