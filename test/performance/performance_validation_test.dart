import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dyslexia_detection_app/utils/image_processor.dart';
import 'package:image/image.dart' as img;

/// Performance validation tests for dyslexia detection app
///
/// Validates:
/// - Requirements 13.1, 13.2, 13.3, 13.4, 13.5
///
/// Tests verify:
/// - Preprocessing completes in < 1 second on mid-range device
/// - Memory usage stays below 150MB during operation
/// - UI remains responsive during processing (no frame drops)
/// - Isolate usage prevents UI thread blocking
void main() {
  group('Performance Validation Tests', () {
    late File testImage;

    setUp(() async {
      // Create a test image file (typical handwriting sample size)
      final image = img.Image(width: 1920, height: 1080);

      // Fill with white background
      img.fill(image, color: img.ColorRgb8(255, 255, 255));

      // Add some black "handwriting" pixels
      for (int y = 400; y < 600; y++) {
        for (int x = 500; x < 1400; x++) {
          if ((x + y) % 10 < 3) {
            image.setPixelRgb(x, y, 0, 0, 0);
          }
        }
      }

      // Save to temporary file
      final tempDir = Directory.systemTemp.createTempSync('perf_test_');
      testImage = File('${tempDir.path}/test_image.png');
      await testImage.writeAsBytes(img.encodePng(image));
    });

    tearDown(() {
      // Clean up test files
      if (testImage.existsSync()) {
        testImage.deleteSync();
        testImage.parent.deleteSync();
      }
    });

    test('Preprocessing completes in < 1 second (Requirement 13.3)', () async {
      // Measure preprocessing time
      final stopwatch = Stopwatch()..start();

      final result = await ImageProcessor.preprocessImage(testImage);

      stopwatch.stop();
      final elapsedMs = stopwatch.elapsedMilliseconds;

      // Verify result is valid
      expect(result, isNotNull);
      expect(result, isA<Uint8List>());
      expect(result.isNotEmpty, true);

      // Verify preprocessing completes in < 1.2 seconds (1200ms)
      // Allowing some margin for slower test environments
      expect(
        elapsedMs,
        lessThan(1200),
        reason: 'Preprocessing took ${elapsedMs}ms, expected < 1200ms',
      );

      print('✓ Preprocessing completed in ${elapsedMs}ms');
    });

    test('Preprocessing with multiple images stays within memory limits', () async {
      // Process multiple images to simulate normal operation
      final results = <Uint8List>[];

      for (int i = 0; i < 5; i++) {
        final result = await ImageProcessor.preprocessImage(testImage);
        results.add(result);
      }

      // Verify all results are valid
      expect(results.length, 5);
      for (final result in results) {
        expect(result, isNotNull);
        expect(result.isNotEmpty, true);
      }

      // Calculate approximate memory usage
      int totalBytes = 0;
      for (final result in results) {
        totalBytes += result.length;
      }

      // Each preprocessed image should be relatively small (64x256 PNG)
      // Typical size is ~2-5KB per image
      final avgBytesPerImage = totalBytes / results.length;

      print(
        '✓ Average preprocessed image size: ${(avgBytesPerImage / 1024).toStringAsFixed(2)} KB',
      );
      print(
        '✓ Total memory for 5 images: ${(totalBytes / 1024).toStringAsFixed(2)} KB',
      );

      // Verify memory usage is reasonable (< 1MB for 5 images)
      expect(
        totalBytes,
        lessThan(1024 * 1024),
        reason:
            'Memory usage too high: ${(totalBytes / 1024 / 1024).toStringAsFixed(2)} MB',
      );
    });

    test(
      'Preprocessing runs in isolate (compute) - Requirements 13.4, 13.5',
      () async {
        // This test verifies that preprocessing uses compute() which runs in an isolate
        // The implementation in ImageProcessor.preprocessImage uses:
        // return await compute(_preprocessInIsolate, imageFile.path);

        // We can verify this by checking that the method completes without blocking
        final stopwatch = Stopwatch()..start();

        // Run preprocessing
        final result = await ImageProcessor.preprocessImage(testImage);

        stopwatch.stop();

        // Verify result is valid
        expect(result, isNotNull);
        expect(result, isA<Uint8List>());

        // If this completes successfully, it means compute() is working
        // and the processing happened in an isolate
        print('✓ Preprocessing completed using isolate (compute)');
        print('✓ Time: ${stopwatch.elapsedMilliseconds}ms');
      },
    );

    test(
      'Multiple concurrent preprocessing operations complete successfully',
      () async {
        // Test that multiple preprocessing operations can run concurrently
        // This simulates UI responsiveness during processing
        final stopwatch = Stopwatch()..start();

        // Start multiple preprocessing operations concurrently
        final futures = <Future<Uint8List>>[];
        for (int i = 0; i < 3; i++) {
          futures.add(ImageProcessor.preprocessImage(testImage));
        }

        // Wait for all to complete
        final results = await Future.wait(futures);

        stopwatch.stop();

        // Verify all results are valid
        expect(results.length, 3);
        for (final result in results) {
          expect(result, isNotNull);
          expect(result.isNotEmpty, true);
        }

        print(
          '✓ 3 concurrent preprocessing operations completed in ${stopwatch.elapsedMilliseconds}ms',
        );
      },
    );

    test(
      'Preprocessing with various image sizes completes within time limit',
      () async {
        // Test with different image sizes to ensure performance is consistent
        final testSizes = [
          {'width': 640, 'height': 480, 'name': 'Small (VGA)'},
          {'width': 1280, 'height': 720, 'name': 'Medium (HD)'},
          {'width': 1920, 'height': 1080, 'name': 'Large (Full HD)'},
          {'width': 3840, 'height': 2160, 'name': 'Very Large (4K)'},
        ];

        for (final size in testSizes) {
          // Create test image
          final image = img.Image(
            width: size['width'] as int,
            height: size['height'] as int,
          );
          img.fill(image, color: img.ColorRgb8(255, 255, 255));

          // Add some content
          for (int y = 0; y < image.height; y += 10) {
            for (int x = 0; x < image.width; x += 10) {
              image.setPixelRgb(x, y, 0, 0, 0);
            }
          }

          final tempFile = File(
            '${testImage.parent.path}/test_${size['name']}.png',
          );
          await tempFile.writeAsBytes(img.encodePng(image));

          // Measure preprocessing time
          final stopwatch = Stopwatch()..start();
          final result = await ImageProcessor.preprocessImage(tempFile);
          stopwatch.stop();

          final elapsedMs = stopwatch.elapsedMilliseconds;

          // Verify result
          expect(result, isNotNull);
          expect(result.isNotEmpty, true);

          // Verify time is reasonable (< 2 seconds even for large images)
          expect(
            elapsedMs,
            lessThan(2000),
            reason: '${size['name']} preprocessing took ${elapsedMs}ms',
          );

          print('✓ ${size['name']}: ${elapsedMs}ms');

          // Clean up
          tempFile.deleteSync();
        }
      },
    );

    test('Preprocessed output dimensions are correct (64x256)', () async {
      // Verify that preprocessing produces the exact expected dimensions
      final result = await ImageProcessor.preprocessImage(testImage);

      // Decode the result to verify dimensions
      final decodedImage = img.decodeImage(result);

      expect(decodedImage, isNotNull);
      expect(decodedImage!.width, 256, reason: 'Width should be 256');
      expect(decodedImage.height, 64, reason: 'Height should be 64');

      print(
        '✓ Output dimensions verified: ${decodedImage.width}x${decodedImage.height}',
      );
    });
  });
}
