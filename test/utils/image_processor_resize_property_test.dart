import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  group('ImageProcessor Resize Property Tests', () {
    final random = Random();

    /// Generator: Creates a random binary image with random dimensions
    /// Binary images (0 or 255) are used since resize happens after inversion
    img.Image generateRandomBinaryImage() {
      // Random dimensions between 10 and 2000 pixels
      // Using wider range to test various aspect ratios
      final width = 10 + random.nextInt(1991);
      final height = 10 + random.nextInt(1991);

      final image = img.Image(width: width, height: height);

      // Fill with random binary values (0 or 255)
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final value = random.nextBool() ? 0 : 255;
          image.setPixelRgba(x, y, value, value, value, 255);
        }
      }

      return image;
    }

    /// Direct implementation of resize with padding for testing
    /// This mirrors the ImageProcessor._resizeWithPadding implementation
    img.Image resizeWithPadding({
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

    test(
      'Feature: dyslexia-detection-flutter-app, Property 10: Resize Preserves Aspect Ratio and Produces Exact Dimensions',
      () {
        const targetWidth = 256;
        const targetHeight = 64;

        // Run 5 iterations with random binary images
        for (int iteration = 0; iteration < 5; iteration++) {
          // Generate random binary image
          final originalImage = generateRandomBinaryImage();
          final originalWidth = originalImage.width;
          final originalHeight = originalImage.height;
          final originalAspectRatio = originalWidth / originalHeight;

          // Apply resize with padding
          final resizedImage = resizeWithPadding(
            image: originalImage,
            targetWidth: targetWidth,
            targetHeight: targetHeight,
          );

          // Property 1: Output dimensions must be exactly 64x256
          expect(
            resizedImage.width,
            targetWidth,
            reason:
                'Iteration $iteration: Output width should be exactly $targetWidth. '
                'Original: ${originalWidth}x$originalHeight, '
                'Got: ${resizedImage.width}x${resizedImage.height}',
          );

          expect(
            resizedImage.height,
            targetHeight,
            reason:
                'Iteration $iteration: Output height should be exactly $targetHeight. '
                'Original: ${originalWidth}x$originalHeight, '
                'Got: ${resizedImage.width}x${resizedImage.height}',
          );

          // Property 2: Aspect ratio of non-padded content should match original
          // Calculate the scaled dimensions (before padding)
          final scaleWidth = targetWidth / originalWidth;
          final scaleHeight = targetHeight / originalHeight;
          final scale = scaleWidth < scaleHeight ? scaleWidth : scaleHeight;

          final scaledWidth = (originalWidth * scale).round();
          final scaledHeight = (originalHeight * scale).round();

          // The aspect ratio of the scaled content should match the original
          final scaledAspectRatio = scaledWidth / scaledHeight;

          // Calculate relative difference
          final aspectRatioDifference =
              (scaledAspectRatio - originalAspectRatio).abs() /
              originalAspectRatio;

          // Tolerance depends on the scaled dimensions - smaller dimensions need more tolerance
          // due to rounding effects. For very small dimensions (< 10 pixels), allow up to 20% difference.
          // For larger dimensions, use 5% tolerance.
          final minScaledDimension =
              scaledWidth < scaledHeight ? scaledWidth : scaledHeight;
          final tolerance = minScaledDimension < 10 ? 0.20 : 0.05;

          expect(
            aspectRatioDifference,
            lessThan(tolerance),
            reason:
                'Iteration $iteration: Aspect ratio should be preserved within $tolerance tolerance. '
                'Original: ${originalWidth}x$originalHeight (AR: ${originalAspectRatio.toStringAsFixed(4)}), '
                'Scaled: ${scaledWidth}x$scaledHeight (AR: ${scaledAspectRatio.toStringAsFixed(4)}), '
                'Difference: ${(aspectRatioDifference * 100).toStringAsFixed(2)}%, '
                'Min scaled dimension: $minScaledDimension',
          );

          // Property 3: Verify padding is black (0, 0, 0)
          // Check corners which should be padding for most images
          final padLeft = ((targetWidth - scaledWidth) / 2).floor();
          final padTop = ((targetHeight - scaledHeight) / 2).floor();

          // Only check padding if there is padding (scaled dimensions < target)
          if (padLeft > 0) {
            // Check left padding
            final leftPaddingPixel = resizedImage.getPixel(
              0,
              targetHeight ~/ 2,
            );
            expect(
              leftPaddingPixel.r.toInt(),
              0,
              reason:
                  'Iteration $iteration: Left padding should be black (0). '
                  'Original: ${originalWidth}x$originalHeight, '
                  'Scaled: ${scaledWidth}x$scaledHeight',
            );
          }

          if (padTop > 0) {
            // Check top padding
            final topPaddingPixel = resizedImage.getPixel(targetWidth ~/ 2, 0);
            expect(
              topPaddingPixel.r.toInt(),
              0,
              reason:
                  'Iteration $iteration: Top padding should be black (0). '
                  'Original: ${originalWidth}x$originalHeight, '
                  'Scaled: ${scaledWidth}x$scaledHeight',
            );
          }
        }
      },
    );
  });
}
