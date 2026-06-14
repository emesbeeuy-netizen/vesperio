import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/user_provider.dart';
import '../widgets/widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isRegisterMode = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final displayName = _displayNameController.text.trim();

    final success = _isRegisterMode
        ? await userProvider.register(email, password, displayName)
        : await userProvider.login(email, password);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isRegisterMode ? 'Registered successfully!' : 'Signed in successfully!')),
      );
      Navigator.of(context).pop();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isRegisterMode ? 'Registration failed.' : 'Invalid credentials.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isRegisterMode ? AppStrings.createAccount : AppStrings.signIn;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Text(
                  title,
                  style: AppTypography.heading1.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xl),
                ModernCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: AppStrings.emailAddress),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter your email address.';
                            }
                            if (!value.contains('@')) {
                              return 'Enter a valid email address.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (_isRegisterMode) ...[
                          TextFormField(
                            controller: _displayNameController,
                            decoration: const InputDecoration(labelText: AppStrings.displayName),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter a display name.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(labelText: AppStrings.password),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter your password.';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: Text(_isSubmitting ? AppStrings.pleaseWait : title),
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isRegisterMode = !_isRegisterMode;
                    });
                  },
                  child: Text(_isRegisterMode
                      ? AppStrings.haveAccount
                      : AppStrings.createAccount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
