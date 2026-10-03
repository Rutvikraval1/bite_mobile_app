import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/table_names.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/profile_mapper.dart';

/// Supabase-backed [AuthRepository].
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({SupabaseClientProvider? provider})
    : _provider = provider ?? SupabaseClientProvider.instance;

  final SupabaseClientProvider _provider;

  GoTrueClient get _auth => _provider.auth;

  SupabaseClient get _client => _provider.client;

  @override
  Stream<AuthUser?> streamAuthUser() {
    return _auth.onAuthStateChange.map((data) {
      final user = data.session?.user;
      return user == null ? null : _userFrom(user);
    });
  }

  @override
  Future<AuthUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    return user == null ? null : _userFrom(user);
  }

  @override
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final res = await _auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = res.user;
      return AuthResult(userId: user?.id);
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String name = '',
    String username = '',
  }) async {
    try {
      final res = await _auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          if (name.isNotEmpty) 'display_name': name,
          if (username.isNotEmpty) 'username': username,
        },
      );
      final user = res.user;
      final session = res.session;
      if (session != null && user != null) {
        // Session present — auto-confirmed. Ensure a profile row exists.
        await _ensureProfile(user.id);
        return AuthResult(userId: user.id);
      }
      // No session — email confirmation required.
      return const AuthResult(needsEmailConfirmation: true);
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  @override
  Future<AuthResult> signInWithProvider(AuthProviderType provider) async {
    OAuthProvider oauth;
    switch (provider) {
      case AuthProviderType.google:
        oauth = OAuthProvider.google;
      case AuthProviderType.apple:
        oauth = OAuthProvider.apple;
      case AuthProviderType.email:
        return const AuthResult(error: 'Use the email form instead');
    }
    try {
      final res = await _auth.getOAuthSignInUrl(provider: oauth);
      await launchUrl(Uri.parse(res.url));
      return const AuthResult();
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  @override
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.resetPasswordForEmail(email.trim());
      return const AuthResult();
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  @override
  Future<AuthResult> updatePassword(String newPassword) async {
    try {
      await _auth.updateUser(UserAttributes(password: newPassword));
      return const AuthResult();
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  @override
  Future<AuthResult> deleteAccount() async {
    try {
      await _client.rpc('delete_own_account');
      await _auth.signOut();
      return const AuthResult();
    } on PostgrestException catch (e) {
      return AuthResult.failure(e.message);
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  @override
  Future<AuthResult> signOut() async {
    try {
      await _auth.signOut();
      return const AuthResult();
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  @override
  Future<AuthResult> updateEmail(String newEmail) async {
    try {
      await _auth.updateUser(UserAttributes(email: newEmail.trim()));
      return const AuthResult();
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  @override
  Future<AuthResult> markOnboarded() async {
    try {
      await _auth.updateUser(UserAttributes(data: {'onboarded': true}));
      return const AuthResult();
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  @override
  Future<ProfileResult> fetchProfile(String userId) async {
    try {
      final res = await _client
          .from(TableNames.profiles)
          .select()
          .eq('id', userId)
          .maybeSingle();
      final row = res;
      if (row == null) {
        return const ProfileResult.failure('Profile not found');
      }
      return ProfileResult.success(ProfileMapper.fromMap(row));
    } catch (e) {
      return ProfileResult.failure(e.toString());
    }
  }

  @override
  Future<ProfileWriteResult> createProfile(
    String userId, {
    String displayName = '',
    String username = '',
  }) async {
    try {
      final row = ProfileMapper.initialMap(userId)
        ..['display_name'] = displayName
        ..['username'] = username;
      await _client.from(TableNames.profiles).upsert(row, onConflict: 'id');
      return ProfileWriteResult.ok;
    } catch (e) {
      return ProfileWriteResult(error: e.toString());
    }
  }

  @override
  Future<ProfileWriteResult> updateProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      // Upsert so the row is created if the signup trigger didn't make one;
      // otherwise only the given columns are updated.
      await _client.from(TableNames.profiles).upsert({
        ...updates,
        'id': userId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'id');
      return ProfileWriteResult.ok;
    } on PostgrestException catch (e) {
      // 23505 = unique_violation (profiles_username_unique).
      return ProfileWriteResult(
        error: e.code == '23505'
            ? 'That username is already taken'
            // PGRST204 / 42703 = unknown column (migration not applied).
            : e.code == 'PGRST204' || e.code == '42703'
                ? 'Database is out of date — run the latest Supabase migration'
                : e.message,
      );
    } catch (e) {
      return ProfileWriteResult(error: e.toString());
    }
  }

  /// Ensures a minimal profile row exists for [userId] (trigger race safety).
  Future<void> _ensureProfile(String userId) async {
    final existing = await fetchProfile(userId);
    if (existing.hasError) {
      await createProfile(userId);
    }
  }

  AuthUser _userFrom(User user) => AuthUser(
    id: user.id,
    email: user.email,
    name: (user.userMetadata?['display_name'] as String?) ?? '',
    username: (user.userMetadata?['username'] as String?) ?? '',
    onboarded: user.userMetadata?['onboarded'] == true,
  );
}
