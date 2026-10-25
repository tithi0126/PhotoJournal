import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ProcessedPhotoResult {
  final String originalPath;
  final String thumbPath;
  final String mediumPath;
  final String largePath;
  final int width;
  final int height;
  final int fileSize;
  final String contentHash;

  ProcessedPhotoResult({
    required this.originalPath,
    required this.thumbPath,
    required this.mediumPath,
    required this.largePath,
    required this.width,
    required this.height,
    required this.fileSize,
    required this.contentHash,
  });
}

class ImageProcessingService {
  /// Ingest raw image bytes, compute hash, extract dimensions, save original & derivatives
  static Future<ProcessedPhotoResult> processImage({
    required String photoId,
    required Uint8List bytes,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final origDir = Directory(p.join(appDir.path, 'photos', 'orig'));
    final derivedDir = Directory(p.join(appDir.path, 'photos', 'derived'));

    if (!await origDir.exists()) await origDir.create(recursive: true);
    if (!await derivedDir.exists()) await derivedDir.create(recursive: true);

    // Compute SHA-256 hash
    final hash = sha256.convert(bytes).toString();

    // Paths
    final originalPath = p.join(origDir.path, '$photoId.jpg');
    final thumbPath = p.join(derivedDir.path, '${photoId}_thumb.jpg');
    final mediumPath = p.join(derivedDir.path, '${photoId}_medium.jpg');
    final largePath = p.join(derivedDir.path, '${photoId}_large.jpg');

    // Save original
    await File(originalPath).writeAsBytes(bytes);

    // Decode image to handle rotation and resizing
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      // Fallback if decoding fails: use original for all paths
      await File(thumbPath).writeAsBytes(bytes);
      await File(mediumPath).writeAsBytes(bytes);
      await File(largePath).writeAsBytes(bytes);

      return ProcessedPhotoResult(
        originalPath: originalPath,
        thumbPath: thumbPath,
        mediumPath: mediumPath,
        largePath: largePath,
        width: 1000,
        height: 1000,
        fileSize: bytes.length,
        contentHash: hash,
      );
    }

    // Orient image properly if needed
    final oriented = img.bakeOrientation(decoded);
    final width = oriented.width;
    final height = oriented.height;

    // 1. Thumbnail (200px square crop for calendar performance)
    final thumb = img.copyResizeCropSquare(oriented, size: 200);
    await File(thumbPath).writeAsBytes(img.encodeJpg(thumb, quality: 80));

    // 2. Medium (800px max dimension for fast feeds & sheets)
    img.Image medium;
    if (width > 800 || height > 800) {
      if (width >= height) {
        medium = img.copyResize(oriented, width: 800);
      } else {
        medium = img.copyResize(oriented, height: 800);
      }
    } else {
      medium = oriented;
    }
    await File(mediumPath).writeAsBytes(img.encodeJpg(medium, quality: 85));

    // 3. Large (2048px max dimension for daily view)
    img.Image large;
    if (width > 2048 || height > 2048) {
      if (width >= height) {
        large = img.copyResize(oriented, width: 2048);
      } else {
        large = img.copyResize(oriented, height: 2048);
      }
    } else {
      large = oriented;
    }
    await File(largePath).writeAsBytes(img.encodeJpg(large, quality: 90));

    return ProcessedPhotoResult(
      originalPath: originalPath,
      thumbPath: thumbPath,
      mediumPath: mediumPath,
      largePath: largePath,
      width: width,
      height: height,
      fileSize: bytes.length,
      contentHash: hash,
    );
  }
}
