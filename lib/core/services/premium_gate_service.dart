import 'dart:async';

import 'toast_service.dart';

/// A premium-gate request — ports `showPremiumGate` / `bite-premium-gate`.
class PremiumGateRequest {
  const PremiumGateRequest({
    required this.feature,
    required this.tier,
    required this.description,
  });

  final String feature;
  final String tier;
  final String description;
}

/// Global premium-gate bus. The widget host checks [isPremium] before
/// surfacing a gate (premium users just get a toast).
class PremiumGateService {
  PremiumGateService._();

  static final PremiumGateService instance = PremiumGateService._();

  final StreamController<PremiumGateRequest> _controller =
      StreamController<PremiumGateRequest>.broadcast();

  Stream<PremiumGateRequest> get stream => _controller.stream;

  bool isPremium = false;
  String userTier = 'free';

  void setPremiumState({required bool premium, required String tier}) {
    isPremium = premium;
    userTier = tier;
  }

  void show(String feature, String tier, String description) {
    if (isPremium) {
      // Premium users: everything is unlocked — just toast.
      ToastService.instance.show('✨ $feature — unlocked!');
      return;
    }
    if (_controller.isClosed) return;
    _controller.add(
      PremiumGateRequest(feature: feature, tier: tier, description: description),
    );
  }

  void dispose() {
    if (!_controller.isClosed) _controller.close();
  }
}
