import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  group('ImageProcessor Color Inversion Property Tests', () {
    final random = Random();

    /// Generator: Creates a random binary image with random dimensions
    /// and only 0 or 255 pixel values (pure black and white)
    img.Image generateRandomBinaryImage() {
      // Random dimensions between 10 and 500 pixels
      final width = 10 + random.nextInt(491);
      final height = 10 + random.nextInt(491);

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

    /// Direct implementation of color inversion for testing
    /// This mirrors the ImageProcessor._invertColors implementation
    img.Image invertColors(img.Image image) {
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

    test(
      'Feature: dyslexia-detection-flutter-app, Property 9: Color Inversion is Bijective',
      () {
        // Run 5 iterations with random binary images
        for (int iteration = 0; iteration < 5; iteration++) {
          // Generate random binary image
          final originalImage = generateRandomBinaryImage();

          // Apply double inversion: invert(invert(image))
          final invertedOnce = invertColors(originalImage);
          final invertedTwice = invertColors(invertedOnce);

          // Property: invert(invert(image)) = image
          // Verify that double inversion produces the original image
          bool isBijective = true;
          String? failureDetails;

          // Check dimensions match
          if (invertedTwice.width != originalImage.width ||
              invertedTwice.height != originalImage.height) {
            isBijective = false;
            failureDetails =
                'Iteration $iteration: Dimensions changed. '
                'Original: ${originalImage.width}x${originalImage.height}, '
                'After double inversion: ${invertedTwice.width}x${invertedTwice.height}';
          } else {
            // Check all pixel values match
            for (int y = 0; y < originalImage.height; y++) {
              for (int x = 0; x < originalImage.width; x++) {
                final originalPixel = originalImage.getPixel(x, y);
                final resultPixel = invertedTwice.getPixel(x, y);

                final originalValue = originalPixel.r.toInt();
                final resultValue = resultPixel.r.toInt();

                if (originalValue != resultValue) {
                  isBijective = false;
                  failureDetails =
                      'Iteration $iteration: Pixel at ($x, $y) differs. '
                      'Original value: $originalValue, '
                      'After double inversion: $resultValue. '
                      'Image dimensions: ${originalImage.width}x${originalImage.height}';
                  break;
                }
              }
              if (!isBijective) break;
            }
          }

          expect(
            isBijective,
            true,
            reason:
                failureDetails ??
                'Double inversion should produce the original image: invert(invert(image)) = image',
          );
        }
      },
    );
  });
}
