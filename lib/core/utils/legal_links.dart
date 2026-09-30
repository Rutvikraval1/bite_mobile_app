import 'package:url_launcher/url_launcher.dart';

import '../config/app_env.dart';
import '../services/toast_service.dart';

/// Opens the Terms of Service / Privacy Policy pages in an in-app web view.
/// URLs come from `TERMS_URL` and `PRIVACY_POLICY_URL` in `.env`.
abstract final class LegalLinks {
  static Future<void> openTerms() => _open(AppEnv.termsUrl);

  static Future<void> openPrivacyPolicy() => _open(AppEnv.privacyPolicyUrl);

  static Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (url.isEmpty || uri == null) {
      ToastService.instance.show('Link unavailable');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.inAppWebView);
    if (!ok) ToastService.instance.show('Could not open link');
  }
}
