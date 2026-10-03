import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/supabase_client_provider.dart';

/// Storage buckets created by the `profile_production` migration.
abstract final class ImageBuckets {
  static const avatars = 'avatars';
  static const recipeImages = 'recipe-images';
}

/// Picks a photo from the camera/gallery and uploads it to Supabase Storage
/// under `<userId>/…` (the only folder the storage policies let a user write).
class ImageUploadService {
  ImageUploadService._();

  static final ImageUploadService instance = ImageUploadService._();

  final ImagePicker _picker = ImagePicker();

  /// Returns null if the user cancelled or the picker failed.
  Future<XFile?> pick(ImageSource source, {double maxSize = 1600}) async {
    try {
      return await _picker.pickImage(
        source: source,
        maxWidth: maxSize,
        maxHeight: maxSize,
        imageQuality: 82,
      );
    } catch (e) {
      debugPrint('[bite] image pick failed: $e');
      return null;
    }
  }

  /// Uploads [file] and returns its public URL. Throws on failure.
  Future<String> upload({
    required String bucket,
    required String userId,
    required XFile file,
  }) async {
    final bytes = await file.readAsBytes();
    final ext = _extension(file);
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    final storage = SupabaseClientProvider.instance.client.storage.from(bucket);
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: file.mimeType ?? 'image/$ext',
        upsert: true,
      ),
    );
    return storage.getPublicUrl(path);
  }

  /// Best-effort delete of a previously uploaded public URL in [bucket].
  Future<void> deleteByUrl(String bucket, String url) async {
    final marker = '/object/public/$bucket/';
    final i = url.indexOf(marker);
    if (i < 0) return;
    try {
      await SupabaseClientProvider.instance.client.storage.from(bucket).remove([
        Uri.decodeComponent(url.substring(i + marker.length)),
      ]);
    } catch (e) {
      debugPrint('[bite] image delete failed: $e');
    }
  }

  /// Human-readable reason for an upload failure (shown in a toast).
  static String describeError(Object e) {
    final msg = e is StorageException ? e.message : e.toString();
    final lower = msg.toLowerCase();
    if (lower.contains('row-level security') || lower.contains('unauthorized')) {
      return 'Upload not allowed — storage policies missing (run the latest Supabase migration)';
    }
    if (lower.contains('bucket not found')) {
      return 'Storage bucket missing (run the latest Supabase migration)';
    }
    if (lower.contains('payload too large') || lower.contains('maximum allowed size')) {
      return 'Photo is too large';
    }
    if (lower.contains('socket') || lower.contains('network') || lower.contains('failed host lookup')) {
      return 'No internet connection';
    }
    return msg;
  }

  static String _extension(XFile file) {
    final name = file.name.toLowerCase();
    final dot = name.lastIndexOf('.');
    final ext = dot >= 0 ? name.substring(dot + 1) : 'jpg';
    return switch (ext) {
      'jpeg' || 'jpg' => 'jpg',
      'png' || 'webp' || 'heic' => ext,
      _ => 'jpg',
    };
  }
}
