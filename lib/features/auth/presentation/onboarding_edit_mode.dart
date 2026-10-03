import '../../../core/router/flow_cubit.dart';
import '../../../core/services/toast_service.dart';

/// Lets Settings reuse the onboarding preference screens as editors.
/// While [active], Continue saves and returns to the previous screen
/// instead of advancing through onboarding.
abstract final class OnboardingEditMode {
  static bool active = false;

  /// Exits edit mode (going back) if it's active. Returns true if handled.
  static bool exit(FlowCubit flow, {bool saved = false}) {
    if (!active) return false;
    active = false;
    if (saved) ToastService.instance.show('✅ Preferences saved');
    flow.goBack();
    return true;
  }
}
