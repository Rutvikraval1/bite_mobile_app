import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/app_safe_area.dart';
import '../blocs/auth_cubit.dart';
import '../widgets/auth_widgets.dart';

/// Forgot password. Ports `ForgotPasswordScreen`.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _sent = false;
  bool _busy = false;
  String _error = '';

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = '';
    });
    final result = await context.read<AuthCubit>().resetPassword(_email.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.isSuccess) {
      setState(() => _sent = true);
    } else {
      setState(() => _error = result.error ?? 'Could not send reset link');
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.read<FlowCubit>();
    return AppSafeArea(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned(
              top: 20,
              left: 20,
              child: AuthBackButton(
                onTap: () => flow.setScreen(AppScreen.emailLogin),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 40),
              child: _sent ? _sentView(flow) : _formView(flow),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formView(FlowCubit flow) {
    return Column(
      children: [
        ZoomIn(child: const Text('🔒', style: TextStyle(fontSize: 56))),
        const SizedBox(height: 16),
        const Text(
          'Forgot your password?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Enter your email and we'll send you a reset link.",
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        const SizedBox(height: 28),
        AuthField(
          controller: _email,
          label: 'Email',
          hint: 'your@email.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        AuthErrorText(message: _error),
        const SizedBox(height: 8),
        AuthPrimaryButton(
          label: _busy ? 'Sending…' : 'Send Reset Link',
          enabled: !_busy,
          onTap: _send,
          glow: true,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => flow.setScreen(AppScreen.emailLogin),
          child: const Text('Back to Login', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  Widget _sentView(FlowCubit flow) {
    return Column(
      children: [
        PopIn(child: const Text('✉️', style: TextStyle(fontSize: 56))),
        const SizedBox(height: 16),
        const Text(
          'Check Your Email',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'We sent a reset link to your email',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => ToastService.instance.show('📧 Reset link resent!'),
          child: const Text(
            "Didn't receive it? Resend",
            style: TextStyle(
              color: AppColors.coral,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => flow.setScreen(AppScreen.emailLogin),
          child: const Text('Back to Login', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}
