import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// ImageProcessor handles the 5-step preprocessing pipeline for dyslexia detection.
///
/// The pipeline transforms raw camera images into the exact format expected by the model:
/// - 64x256 pixels (height x width)
/// - Grayscale
/// - White handwriting on black background
/// - Aspect ratio preserved with black padding
class ImageProcessor {
  /// Preprocesses an image through the complete 5-step pipeline.
  ///
  /// Runs in an isolate using compute() to prevent UI thread blocking.
  ///
  /// Steps:
  /// 1. Grayscale conversion (luminosity method)
  /// 2. Contrast enhancement (factor 1.5)
  /// 3. Binary thresholding (threshold 128)
  /// 4. Color inversion (255 - pixel value)
  /// 5. Aspect-ratio-preserving resize with black padding to 64x256
  ///
  /// Returns: Uint8List of preprocessed image bytes (PNG encoded)
  static Future<Uint8List> preprocessImage(File imageFile) async {
    return await compute(_preprocessInIsolate, imageFile.path);
  }

  /// Internal method that runs in isolate via compute().
  ///
  /// This method performs all preprocessing steps sequentially.
  static Uint8List _preprocessInIsolate(String imagePath) {
    // Load the image from file
    final imageBytes = File(imagePath).readAsBytesSync();
    img.Image? image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Step 1: Grayscale conversion
    image = _convertToGrayscale(image);

    // Step 2: Contrast enhancement
    image = _enhanceContrast(image, factor: 1.5);

    // Step 3: Binary thresholding
    image = _applyBinaryThreshold(image, threshold: 128);

    // Step 4: Color inversion
    image = _invertColors(image);

    // Step 5: Aspect-ratio-preserving resize with padding
    image = _resizeWithPadding(
      image: image,
      targetWidth: 256,
      targetHeight: 64,
    );

    // Encode to PNG (lossless) and return bytes
    return Uint8List.fromList(img.encodePng(image));
  }

  /// Step 1: Converts image to grayscale using luminosity method.
  ///
  /// Formula: gray = 0.299*R + 0.587*G + 0.114*B
  ///
  /// This method provides perceptually accurate grayscale conversion
  /// by weighting colors according to human eye sensitivity.
  static img.Image _convertToGrayscale(img.Image image) {
    final grayscale = img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);

        // Extract RGB components
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        // Apply luminosity method
        final gray = (0.299 * r + 0.587 * g + 0.114 * b).round().clamp(0, 255);

        // Set grayscale pixel (R=G=B)
        grayscale.setPixelRgba(x, y, gray, gray, gray, 255);
      }
    }

    return grayscale;
  }

  /// Step 2: Enhances image contrast by the specified factor.
  ///
  /// Formula: enhanced = ((p - 128) * factor) + 128
  ///
  /// This increases the separation between light and dark regions,
  /// making handwriting more distinct from the background.
  static img.Image _enhanceContrast(img.Image image, {required double factor}) {
    final enhanced = img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final value = pixel.r.toInt();

        // Apply contrast enhancement formula
        final newValue = (((value - 128) * factor) + 128).round().clamp(0, 255);

        enhanced.setPixelRgba(x, y, newValue, newValue, newValue, 255);
      }
    }

    return enhanced;
  }

  /// Step 3: Applies binary thresholding to create pure black and white image.
  ///
  /// Pixels above threshold become white (255), below become black (0).
  ///
  /// This creates clear separation between handwriting and background.
  static img.Image _applyBinaryThreshold(
    img.Image image, {
    required int threshold,
  }) {
    final binary = img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final value = pixel.r.toInt();

        // Apply threshold: above threshold = white, below = black
        final newValue = value > threshold ? 255 : 0;

        binary.setPixelRgba(x, y, newValue, newValue, newValue, 255);
      }
    }

    return binary;
  }

  /// Step 4: Inverts colors (255 - pixel value).
  ///
  /// Transforms black handwriting on white background to
  /// white handwriting on black background (model's expected format).
  static img.Image _invertColors(img.Image image) {
    final inverted = img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final value = pixel.r.toInt();

        // Invert: 255 - value
        final newValue = 255 - value;

        inverted.setPixelRgba(x, y, newValue, newValue, newValue, 255);
      }
    }

    return inverted;
  }

  /// Step 5: Resizes image to target dimensions while preserving aspect ratio.
  ///
  /// The image is scaled to fit within the target dimensions, then padded
  /// with black pixels to reach exactly targetWidth x targetHeight.
  ///
  /// This prevents letter distortion while ensuring exact model input size.
  static img.Image _resizeWithPadding({
    required img.Image image,
    required int targetWidth,
    required int targetHeight,
  }) {
    final originalWidth = image.width;
    final originalHeight = image.height;

    // Calculate scaling factor to fit within target while preserving aspect ratio
    final scaleWidth = targetWidth / originalWidth;
    final scaleHeight = targetHeight / originalHeight;
    final scale = scaleWidth < scaleHeight ? scaleWidth : scaleHeight;

    // Calculate new dimensions after scaling
    final newWidth = (originalWidth * scale).round();
    final newHeight = (originalHeight * scale).round();

    // Resize with nearest neighbor interpolation to preserve binary values
    img.Image resized = img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.nearest,
    );

    // Calculate padding needed to reach target dimensions
    final padLeft = ((targetWidth - newWidth) / 2).floor();
    final padTop = ((targetHeight - newHeight) / 2).floor();

    // Create final image with black background
    final result = img.Image(width: targetWidth, height: targetHeight);

    // Fill with black (0, 0, 0)
    img.fill(result, color: img.ColorRgb8(0, 0, 0));

    // Copy resized image to center with padding
    img.compositeImage(result, resized, dstX: padLeft, dstY: padTop);

    return result;
  }
}
