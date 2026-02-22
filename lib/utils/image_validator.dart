import 'dart:io';
import 'package:image/image.dart' as img;
import '../models/validation_result.dart';

/// Validates images before preprocessing to ensure they meet quality requirements.
///
/// The dyslexia detection model expects white paper with dark handwriting.
/// This validator checks for color variance, contrast, brightness, and
/// appropriate pixel ratios to reject unsuitable images early.
class ImageValidator {
  // Validation thresholds
  static const double _maxColorVariance = 5000.0;
  static const double _minContrast = 30.0;
  static const double _minBrightness = 50.0;
  static const double _maxBrightness = 240.0;
  static const double _minBlackPixelRatio = 0.05;
  static const double _maxBlackPixelRatio = 0.80;
  static const int _thresholdValue = 128;

  /// Validates an image file to ensure it meets quality requirements.
  ///
  /// Performs the following checks:
  /// 1. Color variance - rejects images with too many colors
  /// 2. Contrast - rejects images with low contrast
  /// 3. Brightness - rejects images that are too dark or overexposed
  /// 4. Black pixel ratio - rejects images with unsuitable content ratios
  ///
  /// Returns a [ValidationResult] indicating success or failure with
  /// specific error messages.
  static ValidationResult validateImage(File imageFile) {
    try {
      // Decode the image
      final bytes = imageFile.readAsBytesSync();
      final image = img.decodeImage(bytes);

      if (image == null) {
        return ValidationResult.failure(
          reason: ValidationFailureReason.tooManyColors,
          errorMessage:
              'Unable to decode image. Please select a valid image file.',
        );
      }

      // 1. Color Variance Check
      final colorVarianceResult = _checkColorVariance(image);
      if (!colorVarianceResult.isValid) {
        return colorVarianceResult;
      }

      // 2. Contrast Check
      final contrastResult = _checkContrast(image);
      if (!contrastResult.isValid) {
        return contrastResult;
      }

      // 3. Brightness Check
      final brightnessResult = _checkBrightness(image);
      if (!brightnessResult.isValid) {
        return brightnessResult;
      }

      // 4. Black Pixel Ratio Check (after simulated thresholding)
      final pixelRatioResult = _checkBlackPixelRatio(image);
      if (!pixelRatioResult.isValid) {
        return pixelRatioResult;
      }

      // All checks passed
      return ValidationResult.success();
    } catch (e) {
      return ValidationResult.failure(
        reason: ValidationFailureReason.tooManyColors,
        errorMessage: 'Error validating image: ${e.toString()}',
      );
    }
  }

  /// Helper method to convert image to grayscale using luminosity method.
  ///
  /// Formula: gray = 0.299*R + 0.587*G + 0.114*B
  ///
  /// This avoids the img.grayscale() function which causes issues in image package v4.x
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

  /// Checks if the image has excessive color variance.
  ///
  /// Images with too many colors likely contain colored backgrounds,
  /// multiple objects, or are not white paper with dark handwriting.
  static ValidationResult _checkColorVariance(img.Image image) {
    // Convert to grayscale and calculate variance
    final grayscale = _convertToGrayscale(image);

    double sum = 0.0;
    int pixelCount = 0;

    // Calculate mean
    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        final pixel = grayscale.getPixel(x, y);
        final luminance = pixel.r.toDouble();
        sum += luminance;
        pixelCount++;
      }
    }

    final mean = sum / pixelCount;

    // Calculate variance
    double varianceSum = 0.0;
    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        final pixel = grayscale.getPixel(x, y);
        final luminance = pixel.r.toDouble();
        final diff = luminance - mean;
        varianceSum += diff * diff;
      }
    }

    final variance = varianceSum / pixelCount;

    if (variance > _maxColorVariance) {
      return ValidationResult.failure(
        reason: ValidationFailureReason.tooManyColors,
        errorMessage:
            'Image has too many colors. Please use white paper with dark handwriting only.',
      );
    }

    return ValidationResult.success();
  }

  /// Checks if the image has sufficient contrast.
  ///
  /// Low contrast images make it difficult to distinguish handwriting
  /// from the background, reducing model accuracy.
  static ValidationResult _checkContrast(img.Image image) {
    final grayscale = _convertToGrayscale(image);

    int minLuminance = 255;
    int maxLuminance = 0;

    // Find min and max luminance values
    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        final pixel = grayscale.getPixel(x, y);
        final luminance = pixel.r.toInt();

        if (luminance < minLuminance) {
          minLuminance = luminance;
        }
        if (luminance > maxLuminance) {
          maxLuminance = luminance;
        }
      }
    }

    final contrast = (maxLuminance - minLuminance).toDouble();

    if (contrast < _minContrast) {
      return ValidationResult.failure(
        reason: ValidationFailureReason.lowContrast,
        errorMessage:
            'Image has low contrast. Ensure good lighting and dark handwriting.',
      );
    }

    return ValidationResult.success();
  }

  /// Checks if the image brightness is within acceptable range.
  ///
  /// Images that are too dark or overexposed will not produce
  /// accurate predictions.
  static ValidationResult _checkBrightness(img.Image image) {
    final grayscale = _convertToGrayscale(image);

    double sum = 0.0;
    int pixelCount = 0;

    // Calculate average brightness
    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        final pixel = grayscale.getPixel(x, y);
        final luminance = pixel.r.toDouble();
        sum += luminance;
        pixelCount++;
      }
    }

    final averageBrightness = sum / pixelCount;

    if (averageBrightness < _minBrightness ||
        averageBrightness > _maxBrightness) {
      return ValidationResult.failure(
        reason: ValidationFailureReason.insufficientBrightness,
        errorMessage:
            'Image brightness is unsuitable. Ensure proper lighting without overexposure.',
      );
    }

    return ValidationResult.success();
  }

  /// Checks if the black pixel ratio after thresholding is suitable.
  ///
  /// This simulates the thresholding step to ensure the image has
  /// an appropriate amount of handwriting content. Too few black pixels
  /// means no content, too many means the image is mostly dark.
  static ValidationResult _checkBlackPixelRatio(img.Image image) {
    final grayscale = _convertToGrayscale(image);

    int blackPixels = 0;
    int totalPixels = 0;

    // Apply threshold and count black pixels
    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        final pixel = grayscale.getPixel(x, y);
        final luminance = pixel.r.toInt();

        // Simulate thresholding
        if (luminance <= _thresholdValue) {
          blackPixels++;
        }
        totalPixels++;
      }
    }

    final ratio = blackPixels / totalPixels;

    if (ratio < _minBlackPixelRatio || ratio > _maxBlackPixelRatio) {
      return ValidationResult.failure(
        reason: ValidationFailureReason.invalidBlackPixelRatio,
        errorMessage:
            'Image content ratio is unsuitable. Ensure handwriting fills frame appropriately.',
      );
    }

    return ValidationResult.success();
  }
}
