import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/features/auth/model/auth_failure.dart';
import 'package:test_case/features/auth/model/user_model.dart';
import 'package:test_case/features/auth/providers/providers.dart';
import 'package:test_case/features/auth/widgets/auth_button.dart';
import 'package:test_case/features/auth/widgets/auth_text_field.dart';
import 'package:test_case/features/home/view/home_view.dart';
import 'package:test_case/features/auth/utils/auth_error_handler.dart';
import 'package:test_case/features/auth/utils/auth_form_validator.dart';

class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isAdmin = false;

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    try {
      final failure = await ref.read(authStateProvider.notifier).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            username: _usernameController.text.trim(),
            role: _isAdmin ? UserRole.admin : UserRole.user,
          );

      if (mounted && failure != null) {
        AuthErrorHandler.showError(context, failure);
        return;
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeView()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        AuthErrorHandler.showError(context, const AuthFailure.serverError());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTextField(
                  controller: _usernameController,
                  labelText: 'Username',
                  validator: AuthFormValidator.validateUsername,
                ),
                const SizedBox(height: 16),
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
                SwitchListTile(
                  title: const Text('Admin Account'),
                  value: _isAdmin,
                  onChanged: (bool value) {
                    setState(() {
                      _isAdmin = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (authState.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  AuthButton(
                    onPressed: _handleSubmit,
                    text: 'Register',
                    isLoading: authState.isLoading,
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
}