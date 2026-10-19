import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

/// Service for Firebase Storage operations
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Extract bytes from data URL (for web)
  Uint8List _extractBytesFromDataUrl(String dataUrl) {
    // Remove data URL prefix (e.g., "data:image/jpeg;base64,")
    final base64String = dataUrl.split(',').last;
    return base64Decode(base64String);
  }

  /// Compress and optimize image bytes as JPEG
  Future<Uint8List> _optimizeImage(Uint8List imageBytes) async {
    try {
      // Decode the image
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        // If decode fails, return original bytes
        return imageBytes;
      }

      // Resize to reduce file size and upload time
      // Max 1280x1280 for faster processing and smaller files
      img.Image processedImage = decodedImage;
      if (decodedImage.width > 1280 || decodedImage.height > 1280) {
        final aspectRatio = decodedImage.width / decodedImage.height;
        int newWidth, newHeight;

        if (decodedImage.width > decodedImage.height) {
          newWidth = 1280;
          newHeight = (1280 / aspectRatio).round();
        } else {
          newHeight = 1280;
          newWidth = (1280 * aspectRatio).round();
        }

        processedImage = img.copyResize(
          decodedImage,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );
      }

      // Encode as JPEG with quality 85 (better compression than PNG for photos)
      final jpegBytes = img.encodeJpg(processedImage, quality: 85);
      return Uint8List.fromList(jpegBytes);
    } catch (e) {
      // If optimization fails, return original bytes
      return imageBytes;
    }
  }

  /// Upload photo to Firebase Storage and return download URL
  /// Returns the download URL as a String, throws Exception on failure
  Future<String> uploadPhoto(
      XFile photoFile, String userId, String memoryId) async {
    try {
      // Always use JPEG format for consistent storage and better compression
      final String fileName =
          'memories/$userId/$memoryId/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Get storage reference - ensure we're using the correct bucket
      Reference ref = _storage.ref().child(fileName);
      
      // Verify user is authenticated before upload
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to upload photos');
      }
      
      // Refresh the auth token to ensure it's valid
      await user.getIdToken(true);

      // Read image bytes - handle data URLs on web
      Uint8List imageBytes;
      if (kIsWeb && photoFile.path.startsWith('data:')) {
        imageBytes = _extractBytesFromDataUrl(photoFile.path);
      } else {
        imageBytes = await photoFile.readAsBytes();
      }

      // Optimize image (compress and resize if needed, convert to JPEG)
      Uint8List optimizedBytes = await _optimizeImage(imageBytes);

      // Always use JPEG content type since we're converting to JPEG
      String contentType = 'image/jpeg';

      // Upload optimized image
      UploadTask uploadTask;
      try {
        uploadTask = ref.putData(
          optimizedBytes,
          SettableMetadata(
            contentType: contentType,
            cacheControl: 'public, max-age=31536000',
          ),
        );
      } catch (e) {
        throw Exception('Failed to create upload task: ${e.toString()}');
      }

      // Wait for upload with extended timeout
      try {
        await uploadTask.timeout(
          const Duration(seconds: 180), // Further extended timeout (3 minutes)
          onTimeout: () {
            throw Exception(
                'Upload timed out. Please check your connection and try again.');
          },
        );
      } catch (e) {
        // Check if it's a CORS or permission error
        if (e.toString().contains('CORS') ||
            e.toString().contains('permission') ||
            e.toString().contains('403')) {
          throw Exception(
              'Upload failed: Please check Firebase Storage security rules. Make sure authenticated users can write to the memories/ path.');
        }
        rethrow;
      }

      final String downloadUrl = await ref.getDownloadURL().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception(
              'Failed to get download URL. The upload may have completed but verification timed out.');
        },
      );

      // Ensure we have a valid URL
      if (downloadUrl.isEmpty) {
        throw Exception('Received empty download URL from Firebase Storage');
      }

      return downloadUrl;
    } catch (e, stackTrace) {
      // Provide more helpful error messages
      String errorMessage = 'Failed to upload photo: ${e.toString()}';
      if (e.toString().contains('CORS')) {
        errorMessage =
            'CORS error: Please check Firebase Storage security rules and ensure they allow uploads from your domain.';
      } else if (e.toString().contains('permission') ||
          e.toString().contains('403')) {
        errorMessage =
            'Permission denied: Please check Firebase Storage security rules. Users need write permission to upload photos.';
      }

      throw Exception(errorMessage);
    }
  }

  /// Delete photo from Firebase Storage
  Future<void> deletePhoto(String photoUrl) async {
    try {
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();
    } catch (e) {
      // Don't throw - photo might already be deleted
    }
  }
}
