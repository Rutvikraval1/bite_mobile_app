import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/state/app_state_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';

/// Creator-tipping bottom sheet — ports `TipFlowScreen` from
/// `screens-misc.jsx`, satisfying `AppScreen.tipFlow`.
///
/// There is no payments/tipping backend, so a "tip" is simulated by
/// deducting the amount from the local `biteCoins` balance
/// ([AppStateCubit.setBiteCoins]) and showing a success toast — no real
/// charge occurs. The "Pay"/"G Pay" rows and Stripe footer are decorative,
/// matching the prototype (they only ever showed a placeholder toast there
/// too).
///
/// No trigger site exists yet in this codebase (a creator profile / recipe
/// "tip" button lives in another phase), so the creator identity is exposed
/// as optional constructor params with placeholder defaults matching the
/// prototype's demo creator. Wire the real creator through these params
/// once that trigger site is ported.
class TipFlowScreen extends StatefulWidget {
  const TipFlowScreen({
    super.key,
    this.creatorHandle = '@chefpriya',
    this.creatorEmoji = '👩‍🍳',
    this.creatorTagline = 'Mastering the art of spice',
  });

  final String creatorHandle;
  final String creatorEmoji;
  final String creatorTagline;

  @override
  State<TipFlowScreen> createState() => _TipFlowScreenState();
}

class _TipFlowScreenState extends State<TipFlowScreen> {
  static const List<int> _amounts = [3, 5, 10];
  static const Map<int, String> _amountEmoji = {3: '☕', 5: '🌶', 10: '🔥'};

  int _tipAmt = 5;
  bool _sending = false;
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _goBack() => context.read<FlowCubit>().goBack();

  Future<void> _sendTip() async {
    if (_sending) return;
    final appState = context.read<AppStateCubit>();
    final coins = appState.state.biteCoins;
    if (coins < _tipAmt) {
      ToastService.instance.show(
        "🪙 Not enough Bite Coins for a \$$_tipAmt tip",
      );
      return;
    }
    HapticsService.medium();
    setState(() => _sending = true);
    appState.setBiteCoins(coins - _tipAmt);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    ToastService.instance.show(
      '🌶 \$$_tipAmt tip sent to ${widget.creatorHandle}!',
    );
    _goBack();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          const ModalBarrier(color: Color(0x99000000), dismissible: false),
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideUp(
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.85,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.bgDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: _goBack,
                          child: Container(
                            width: 48,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: 56,
                          height: 56,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.coral, AppColors.amber],
                            ),
                            border: Border.all(
                              color: AppColors.coral,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            widget.creatorEmoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        Text(
                          widget.creatorHandle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                        Text(
                          widget.creatorTagline,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Thank ${widget.creatorHandle} for the amazing '
                          'recipes! 🌶',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                        Text(
                          'Your tip supports independent creators',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final a in _amounts) _amountButton(a),
                          ],
                        ),
                        TextButton(
                          onPressed: () => ToastService.instance.show(
                            '💰 Custom tip amount coming soon',
                          ),
                          child: const Text(
                            'or enter custom amount',
                            style: TextStyle(
                              color: AppColors.coral,
                              fontSize: 12,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.glass,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  maxLength: 50,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontFamily: 'Inter',
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    counterText: '',
                                    filled: false,
                                    border: InputBorder.none,
                                    hintText: 'Say something nice (optional)',
                                    hintStyle: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 13,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ),
                              ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _messageController,
                                builder: (context, value, _) => Text(
                                  '${value.text.length}/50',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _sendTip,
                          child: Container(
                            width: double.infinity,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppColors.coral, AppColors.coralDark],
                              ),
                            ),
                            child: _sending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Send \$$_tipAmt Tip 🌶',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withValues(alpha: 0.06),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'OR PAY WITH',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withValues(alpha: 0.06),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(child: _payButton(' Pay')),
                            const SizedBox(width: 10),
                            Expanded(child: _payButton('G Pay')),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            '🔒 Powered by Stripe',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 10,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountButton(int amount) {
    final selected = _tipAmt == amount;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: GestureDetector(
        onTap: () {
          HapticsService.selection();
          setState(() => _tipAmt = amount);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.coral.withValues(alpha: 0.13)
                : AppColors.glass,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.coral : AppColors.glassBorder,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _amountEmoji[amount] ?? '',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                '\$$amount',
                style: TextStyle(
                  color: selected ? AppColors.coral : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _payButton(String label) {
    return GestureDetector(
      onTap: () => ToastService.instance.show('💳 Processing payment...'),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: AppColors.glass,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}
