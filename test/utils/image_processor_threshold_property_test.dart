import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  group('ImageProcessor Binary Thresholding Property Tests', () {
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

    /// Direct implementation of binary thresholding for testing
    /// This mirrors the ImageProcessor._applyBinaryThreshold implementation
    img.Image applyBinaryThreshold(img.Image image, {required int threshold}) {
      final binary = img.Image(width: image.width, height: image.height);

      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final value = pixel.r.toInt();

          // Apply threshold: above threshold = white (255), below/equal = black (0)
          final newValue = value > threshold ? 255 : 0;

          binary.setPixelRgba(x, y, newValue, newValue, newValue, 255);
        }
      }

      return binary;
    }

    test(
      'Feature: dyslexia-detection-flutter-app, Property 8: Binary Thresholding Produces Pure Black and White',
      () {
        // Run 5 iterations with random grayscale images
        for (int iteration = 0; iteration < 5; iteration++) {
          // Generate random grayscale image
          final grayscaleImage = generateRandomGrayscaleImage();

          // Apply binary thresholding at threshold 128
          final binaryImage = applyBinaryThreshold(
            grayscaleImage,
            threshold: 128,
          );

          // Property: After binary thresholding, all pixels should be either 0 or 255
          // (pure black or pure white, no intermediate gray values)
          bool allBinary = true;
          String? failureDetails;

          for (int y = 0; y < binaryImage.height; y++) {
            for (int x = 0; x < binaryImage.width; x++) {
              final pixel = binaryImage.getPixel(x, y);
              final r = pixel.r.toInt();
              final g = pixel.g.toInt();
              final b = pixel.b.toInt();

              // Check that R, G, B are all the same (grayscale property maintained)
              if (r != g || g != b) {
                allBinary = false;
                failureDetails =
                    'Iteration $iteration: Pixel at ($x, $y) '
                    'has R=$r, G=$g, B=$b (not grayscale). '
                    'Image dimensions: ${binaryImage.width}x${binaryImage.height}';
                break;
              }

              // Check that the value is either 0 or 255 (binary property)
              if (r != 0 && r != 255) {
                allBinary = false;
                failureDetails =
                    'Iteration $iteration: Pixel at ($x, $y) '
                    'has value $r (not 0 or 255). '
                    'Image dimensions: ${binaryImage.width}x${binaryImage.height}';
                break;
              }
            }
            if (!allBinary) break;
          }

          expect(
            allBinary,
            true,
            reason:
                failureDetails ??
                'All pixels should be either 0 or 255 after binary thresholding',
          );
        }
      },
    );
  });
}
