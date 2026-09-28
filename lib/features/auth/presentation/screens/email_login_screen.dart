import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/auth_result.dart';
import '../blocs/auth_cubit.dart';
import '../widgets/auth_widgets.dart';

/// Email + password login. Ports `EmailLoginScreen`.
class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  String _error = '';

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _error = '';
    });
    final result = await context.read<AuthCubit>().signIn(
      _email.text,
      _pass.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.isSuccess) {
      // Auth stream handles profile load + routing.
    } else {
      setState(() => _error = result.error ?? 'Something went wrong');
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.read<FlowCubit>();
    final auth = context.read<AuthCubit>();
    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthBackButton(
            onTap: () => flow.setScreen(AppScreen.auth),
            label: 'Back to Sign In',
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome Back 🌶',
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
            'Log in to continue cooking',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          const SizedBox(height: 32),
          AuthField(
            controller: _email,
            label: 'Email',
            hint: 'your@email.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          AuthField(
            controller: _pass,
            label: 'Password',
            hint: '••••••••',
            obscure: true,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => flow.setScreen(AppScreen.forgotPassword),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  color: AppColors.coral,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          AuthErrorText(message: _error),
          const SizedBox(height: 12),
          AuthPrimaryButton(
            label: _busy ? 'Logging in…' : 'Log In',
            enabled: !_busy,
            onTap: _login,
            glow: true,
          ),
          const SizedBox(height: 24),
          const AuthOrDivider(),
          const SizedBox(height: 24),
          OAuthRow(
            onGoogle: () {
              auth.signInWithProvider(AuthProviderType.google);
              ToastService.instance.show('🔗 Connecting Google…');
            },
            onApple: () {
              auth.signInWithProvider(AuthProviderType.apple);
              ToastService.instance.show('🔗 Connecting Apple…');
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => flow.setScreen(AppScreen.emailSignup),
            child: const Text(
              "Don't have an account? Sign up",
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
