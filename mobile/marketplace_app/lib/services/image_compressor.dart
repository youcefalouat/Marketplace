import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageCompressor {
  // Config
  static const int _maxWidth = 1200;
  static const int _quality = 80;

  /// Compresses a list of images using `flutter_image_compress` in an isolate.
  /// 
  /// - Resizes to max 1200px width.
  /// - Compresses to WebP (if supported) or JPEG fallback.
  /// - Quality target: 80.
  /// - Strips EXIF metadata automatically (default behavior of flutter_image_compress).
  static Future<List<File>> compressImages(List<File> files) async {
    if (files.isEmpty) return [];

    final tempDir = await getTemporaryDirectory();
    final tempPath = tempDir.path;

    // Use compute to run in a background isolate (avoids blocking the UI)
    final args = _CompressArgs(
      files: files.map((f) => f.path).toList(),
      tempPath: tempPath,
    );

    final compressedPaths = await compute(_compressInIsolate, args);
    return compressedPaths.map((path) => File(path)).toList();
  }

  // --- Isolate Logic ---
  
  static Future<List<String>> _compressInIsolate(_CompressArgs args) async {
    final resultPaths = <String>[];

    for (final originalPath in args.files) {
      final file = File(originalPath);
      if (!file.existsSync()) continue;

      // Hash original file to create a unique temp name
      final bytes = await file.readAsBytes();
      final hash = sha256.convert(bytes).toString().substring(0, 16);
      
      // Determine format (WebP is preferred, but fallback to JPEG on some older iOS if needed)
      // flutter_image_compress handles the actual extension and encoding.
      final targetPath = '${args.tempPath}/compressed_$hash.webp';
      
      try {
        final result = await FlutterImageCompress.compressAndGetFile(
          originalPath,
          targetPath,
          quality: _quality,
          minWidth: _maxWidth,
          format: CompressFormat.webp,
        );
        
        if (result != null) {
          resultPaths.add(result.path);
        } else {
          // Compression failed or format not supported, fallback to jpeg
          final fallbackPath = '${args.tempPath}/compressed_$hash.jpg';
          final fallbackResult = await FlutterImageCompress.compressAndGetFile(
            originalPath,
            fallbackPath,
            quality: _quality,
            minWidth: _maxWidth,
            format: CompressFormat.jpeg,
          );
          if (fallbackResult != null) {
            resultPaths.add(fallbackResult.path);
          } else {
            // Absolute failure, just use original
            resultPaths.add(originalPath);
          }
        }
      } catch (e) {
        debugPrint('Image compression error: $e');
        // On error, fallback to original to at least allow upload
        resultPaths.add(originalPath);
      }
    }

    return resultPaths;
  }
}

class _CompressArgs {
  final List<String> files;
  final String tempPath;

  _CompressArgs({required this.files, required this.tempPath});
}
