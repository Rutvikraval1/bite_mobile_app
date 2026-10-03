import '../entities/auth_result.dart';
import '../entities/profile.dart';

/// Handles authentication and profile persistence.
abstract interface class AuthRepository {
  Stream<AuthUser?> streamAuthUser();

  Future<AuthUser?> getCurrentUser();

  Future<AuthResult> signInWithEmail(String email, String password);

  Future<AuthResult> signUp({
    required String email,
    required String password,
    String name,
    String username,
  });

  Future<AuthResult> signInWithProvider(AuthProviderType provider);

  Future<AuthResult> resetPassword(String email);

  Future<AuthResult> updatePassword(String newPassword);

  /// Starts an email change; Supabase emails a confirmation link.
  Future<AuthResult> updateEmail(String newEmail);

  Future<AuthResult> deleteAccount();

  Future<AuthResult> signOut();

  /// Flags the current user as having completed signup onboarding.
  Future<AuthResult> markOnboarded();

  Future<ProfileResult> fetchProfile(String userId);

  Future<ProfileWriteResult> createProfile(
    String userId, {
    String displayName = '',
    String username = '',
  });

  Future<ProfileWriteResult> updateProfile(
    String userId,
    Map<String, dynamic> updates,
  );
}
