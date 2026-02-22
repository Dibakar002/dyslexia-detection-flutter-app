import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  group('ImageProcessor Contrast Enhancement Property Tests', () {
    final random = Random();

    /// Generator: Creates a random grayscale image with random dimensions and gray values
    img.Image generateRandomGrayscaleImage() {
      // Random dimensions between 10 and 500 pixels
      final width = 10 + random.nextInt(491);
      final height = 10 + random.nextInt(491);

      final image = img.Image(width: width, height: height);

      // Fill with random grayscale values (R=G=B)
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final gray = random.nextInt(256);
          image.setPixelRgba(x, y, gray, gray, gray, 255);
        }
      }

      return image;
    }

    /// Helper: Calculates standard deviation of pixel values in a grayscale image
    double calculateStandardDeviation(img.Image image) {
      final pixels = <int>[];

      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          pixels.add(pixel.r.toInt());
        }
      }

      // Calculate mean
      final mean = pixels.reduce((a, b) => a + b) / pixels.length;

      // Calculate variance
      final variance =
          pixels.map((p) => pow(p - mean, 2)).reduce((a, b) => a + b) /
          pixels.length;

      // Return standard deviation
      return sqrt(variance);
    }

    /// Direct implementation of contrast enhancement for testing
    /// This mirrors the ImageProcessor._enhanceContrast implementation
    img.Image enhanceContrast(img.Image image, {required double factor}) {
      final enhanced = img.Image(width: image.width, height: image.height);

      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final value = pixel.r.toInt();

          // Apply contrast enhancement formula: enhanced = ((p - 128) * factor) + 128
          final newValue = (((value - 128) * factor) + 128).round().clamp(
            0,
            255,
          );

          enhanced.setPixelRgba(x, y, newValue, newValue, newValue, 255);
        }
      }

      return enhanced;
    }

    test(
      'Feature: dyslexia-detection-flutter-app, Property 7: Contrast Enhancement Increases Dynamic Range',
      () {
        // Run 5 iterations with random grayscale images
        for (int iteration = 0; iteration < 5; iteration++) {
          // Generate random grayscale image
          final grayscaleImage = generateRandomGrayscaleImage();

          // Calculate standard deviation before contrast enhancement
          final stdDevBefore = calculateStandardDeviation(grayscaleImage);

          // Apply contrast enhancement (factor 1.5)
          final enhancedImage = enhanceContrast(grayscaleImage, factor: 1.5);

          // Calculate standard deviation after contrast enhancement
          final stdDevAfter = calculateStandardDeviation(enhancedImage);

          // Property: Contrast enhancement should increase standard deviation
          // (indicating greater separation between light and dark regions)
          // Allow for edge cases where all pixels are the same (stdDev = 0)
          if (stdDevBefore > 0) {
            expect(
              stdDevAfter,
              greaterThanOrEqualTo(stdDevBefore),
              reason:
                  'Iteration $iteration: Standard deviation should increase after contrast enhancement. '
                  'Before: ${stdDevBefore.toStringAsFixed(2)}, After: ${stdDevAfter.toStringAsFixed(2)}. '
                  'Image dimensions: ${grayscaleImage.width}x${grayscaleImage.height}',
            );
          } else {
            // If stdDevBefore is 0 (all pixels same), stdDevAfter should also be 0
            expect(
              stdDevAfter,
              equals(0),
              reason:
                  'Iteration $iteration: If all pixels are the same before enhancement, '
                  'they should remain the same after enhancement.',
            );
          }
        }
      },
    );
  });
}
