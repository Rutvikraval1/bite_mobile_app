import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../blocs/auth_cubit.dart';
import '../widgets/auth_widgets.dart';

/// Email sign-up. Ports `EmailSignupScreen`.
class EmailSignupScreen extends StatefulWidget {
  const EmailSignupScreen({super.key});

  @override
  State<EmailSignupScreen> createState() => _EmailSignupScreenState();
}

class _EmailSignupScreenState extends State<EmailSignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String _error = '';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_name.text.isEmpty || _email.text.isEmpty || _pass.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }
    if (_pass.text != _confirm.text) {
      setState(() => _error = "Passwords don't match");
      return;
    }
    setState(() {
      _busy = true;
      _error = '';
    });
    final result = await context.read<AuthCubit>().signUp(
      email: _email.text,
      password: _pass.text,
      name: _name.text,
      username: '',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.isSuccess) {
      if (result.needsEmailConfirmation) {
        ToastService.instance.show('📧 Check your inbox to confirm your email');
      }
      // Otherwise the auth stream routes to the deck.
    } else {
      setState(() => _error = result.error ?? 'Something went wrong');
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.read<FlowCubit>();
    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthBackButton(
            onTap: () => flow.setScreen(AppScreen.auth),
            label: 'Back to Sign In',
          ),
          const SizedBox(height: 16),
          const Text(
            'Create Account 🌶',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Join thousands of home cooks',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          const SizedBox(height: 28),
          AuthField(
            controller: _name,
            label: 'Display Name',
            hint: 'Chef Amazing',
            onChanged: (_) => setState(() => _error = ''),
          ),
          const SizedBox(height: 16),
          AuthField(
            controller: _email,
            label: 'Email',
            hint: 'your@email.com',
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() => _error = ''),
          ),
          const SizedBox(height: 16),
          AuthField(
            controller: _pass,
            label: 'Password',
            hint: 'Min 8 characters',
            obscure: true,
            onChanged: (_) => setState(() => _error = ''),
          ),
          const SizedBox(height: 16),
          AuthField(
            controller: _confirm,
            label: 'Confirm Password',
            hint: '••••••••',
            obscure: true,
            onChanged: (_) => setState(() => _error = ''),
          ),
          const SizedBox(height: 8),
          const Text(
            'At least 8 characters, one uppercase, one number',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          AuthErrorText(message: _error),
          const SizedBox(height: 12),
          AuthPrimaryButton(
            label: _busy ? 'Creating account…' : 'Create Account 🌶',
            enabled: !_busy,
            onTap: _signup,
            glow: true,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => flow.setScreen(AppScreen.emailLogin),
            child: const Text(
              'Already have an account? Log in',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "By signing up, you agree to b🌶te's Terms of Service and Privacy Policy.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0x33FFFFFF),
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
