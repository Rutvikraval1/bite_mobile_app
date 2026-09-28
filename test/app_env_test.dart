import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:bite/core/config/app_env.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppEnv picks up SUPABASE values from the runtime .env asset', () async {
    await dotenv.load(fileName: '.env');

    expect(AppEnv.supabaseUrl, isNotEmpty);
    expect(AppEnv.supabaseAnonKey, isNotEmpty);
    expect(AppEnv.hasSupabaseConfig, isTrue);
  });
}
