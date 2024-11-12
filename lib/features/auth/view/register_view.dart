import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/features/auth/model/auth_failure.dart';
import 'package:test_case/features/auth/model/user_model.dart';
import 'package:test_case/features/auth/providers/providers.dart';
import 'package:test_case/features/auth/widgets/auth_button.dart';
import 'package:test_case/features/auth/widgets/auth_text_field.dart';
import 'package:test_case/features/home/view/home_view.dart';

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
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final failure = await ref.read(authStateProvider.notifier).signUp(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              username: _usernameController.text.trim(),
              role: _isAdmin ? UserRole.admin : UserRole.user,
            );

        if (mounted && failure != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.toErrorMessage()),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Force navigation after successful registration
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeView()),
            (route) => false,
          );
        }
      } catch (e) {
        print('Registration error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('An error occurred during registration'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    if (value.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
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