import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:dyslexia_detection_app/utils/image_processor.dart';
import 'package:image/image.dart' as img;

void main() {
  group('ImageProcessor Property Tests', () {
    late Directory tempDir;
    final random = Random();

    setUp(() {
      // Create temporary directory for test images
      tempDir = Directory.systemTemp.createTempSync('image_processor_pbt_');
    });

    tearDown(() {
      // Clean up temporary directory
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    /// Helper function to create a test image file
    File createTestImage(img.Image image, String filename) {
      final file = File('${tempDir.path}/$filename');
      file.writeAsBytesSync(img.encodePng(image));
      return file;
    }

    /// Generator: Creates a random color image with random dimensions and RGB values
    img.Image generateRandomColorImage() {
      // Random dimensions between 10 and 500 pixels
      final width = 10 + random.nextInt(491);
      final height = 10 + random.nextInt(491);

      final image = img.Image(width: width, height: height);

      // Fill with random RGB values
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final r = random.nextInt(256);
          final g = random.nextInt(256);
          final b = random.nextInt(256);
          image.setPixelRgba(x, y, r, g, b, 255);
        }
      }

      return image;
    }

    test(
      'Feature: dyslexia-detection-flutter-app, Property 6: Grayscale Conversion Produces Monochrome Output',
      () async {
        // Run 25 iterations with random color images
        for (int iteration = 0; iteration < 5; iteration++) {
          // Generate random color image
          final colorImage = generateRandomColorImage();
          final file = createTestImage(
            colorImage,
            'random_color_$iteration.png',
          );

          // Preprocess the image (includes grayscale conversion)
          final result = await ImageProcessor.preprocessImage(file);
          final processedImage = img.decodeImage(result);

          expect(
            processedImage,
            isNotNull,
            reason: 'Iteration $iteration: Failed to decode processed image',
          );

          // Property: After grayscale conversion, all pixels should have R=G=B
          bool allMonochrome = true;
          String? failureDetails;

          for (int y = 0; y < processedImage!.height; y++) {
            for (int x = 0; x < processedImage.width; x++) {
              final pixel = processedImage.getPixel(x, y);
              final r = pixel.r.toInt();
              final g = pixel.g.toInt();
              final b = pixel.b.toInt();

              if (r != g || g != b) {
                allMonochrome = false;
                failureDetails =
                    'Iteration $iteration: Pixel at ($x, $y) '
                    'has R=$r, G=$g, B=$b (not monochrome). '
                    'Original image dimensions: ${colorImage.width}x${colorImage.height}';
                break;
              }
            }
            if (!allMonochrome) break;
          }

          expect(
            allMonochrome,
            true,
            reason:
                failureDetails ??
                'All pixels should have equal R, G, and B values after grayscale conversion',
          );
        }
      },
    );
  });
}
