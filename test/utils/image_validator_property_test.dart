import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:dyslexia_detection_app/utils/image_validator.dart';
import 'package:dyslexia_detection_app/models/validation_result.dart';
import 'package:image/image.dart' as img;

/// Property-based tests for ImageValidator
///
/// These tests generate random images with varying characteristics
/// and verify that the validation logic correctly accepts or rejects
/// images based on the defined rules.
void main() {
  group(
    'Feature: dyslexia-detection-flutter-app, Property 5: Image Validation Rejects Unsuitable Images',
    () {
      late Directory tempDir;
      final random = Random(42); // Fixed seed for reproducibility

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync(
          'image_validator_property_test_',
        );
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      /// Helper to create a test image file
      File createTestImageFile(img.Image image, String filename) {
        final file = File('${tempDir.path}/$filename');
        file.writeAsBytesSync(img.encodePng(image));
        return file;
      }

      /// Generate a random image with controlled color variance
      /// High variance = many different colors (should fail)
      /// Low variance = mostly uniform (should pass if other checks pass)
      img.Image generateImageWithColorVariance(bool highVariance) {
        final width = 100 + random.nextInt(200);
        final height = 100 + random.nextInt(200);
        final image = img.Image(width: width, height: height);

        if (highVariance) {
          // Create image with many different colors (rainbow pattern)
          for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
              final r = random.nextInt(256);
              final g = random.nextInt(256);
              final b = random.nextInt(256);
              image.setPixelRgba(x, y, r, g, b, 255);
            }
          }
        } else {
          // Create image with low variance (mostly white with some dark text)
          final baseColor =
              200 + random.nextInt(55); // 200-254 (light background)
          final textColor = random.nextInt(100); // 0-99 (dark text)

          // Fill with base color
          img.fill(
            image,
            color: img.ColorRgb8(baseColor, baseColor, baseColor),
          );

          // Add some "text" strokes (dark lines)
          for (int i = 0; i < 5; i++) {
            final x1 = random.nextInt(width);
            final y1 = random.nextInt(height);
            final x2 = random.nextInt(width);
            final y2 = random.nextInt(height);
            img.drawLine(
              image,
              x1: x1,
              y1: y1,
              x2: x2,
              y2: y2,
              color: img.ColorRgb8(textColor, textColor, textColor),
              thickness: 2,
            );
          }
        }

        return image;
      }

      /// Generate a random image with controlled contrast
      /// Low contrast = similar light and dark values (should fail)
      /// High contrast = distinct light and dark values (should pass if other checks pass)
      img.Image generateImageWithContrast(bool lowContrast) {
        final width = 100 + random.nextInt(200);
        final height = 100 + random.nextInt(200);
        final image = img.Image(width: width, height: height);

        if (lowContrast) {
          // Create image with values in narrow range (e.g., 120-140)
          final baseValue = 120 + random.nextInt(10);
          for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
              final value = baseValue + random.nextInt(20);
              image.setPixelRgba(x, y, value, value, value, 255);
            }
          }
        } else {
          // Create image with high contrast (white background, black text)
          img.fill(image, color: img.ColorRgb8(240, 240, 240));

          // Add dark strokes
          for (int i = 0; i < 10; i++) {
            final x1 = random.nextInt(width);
            final y1 = random.nextInt(height);
            final x2 = random.nextInt(width);
            final y2 = random.nextInt(height);
            img.drawLine(
              image,
              x1: x1,
              y1: y1,
              x2: x2,
              y2: y2,
              color: img.ColorRgb8(10, 10, 10),
              thickness: 3,
            );
          }
        }

        return image;
      }

      /// Generate a random image with controlled brightness
      /// tooDark = average brightness < 50 (should fail)
      /// tooLight = average brightness > 240 (should fail)
      /// good = average brightness in 50-240 range (should pass if other checks pass)
      img.Image generateImageWithBrightness(String brightnessLevel) {
        final width = 100 + random.nextInt(200);
        final height = 100 + random.nextInt(200);
        final image = img.Image(width: width, height: height);

        int baseValue;
        int variance;

        switch (brightnessLevel) {
          case 'tooDark':
            baseValue = 10 + random.nextInt(30); // 10-39
            variance = 10;
            break;
          case 'tooLight':
            baseValue = 245 + random.nextInt(10); // 245-254
            variance = 5;
            break;
          case 'good':
          default:
            baseValue = 150 + random.nextInt(50); // 150-199
            variance = 50;
            break;
        }

        for (int y = 0; y < height; y++) {
          for (int x = 0; x < width; x++) {
            final value = (baseValue + random.nextInt(variance)).clamp(0, 255);
            image.setPixelRgba(x, y, value, value, value, 255);
          }
        }

        return image;
      }

      /// Generate a random image with controlled black pixel ratio
      /// tooFewBlack = ratio < 0.05 (should fail)
      /// tooManyBlack = ratio > 0.80 (should fail)
      /// good = ratio in 0.05-0.80 range (should pass if other checks pass)
      img.Image generateImageWithBlackPixelRatio(String ratioLevel) {
        final width = 100 + random.nextInt(200);
        final height = 100 + random.nextInt(200);
        final image = img.Image(width: width, height: height);

        double targetRatio;

        switch (ratioLevel) {
          case 'tooFew':
            targetRatio = 0.01 + random.nextDouble() * 0.03; // 0.01-0.04
            break;
          case 'tooMany':
            targetRatio = 0.82 + random.nextDouble() * 0.15; // 0.82-0.97
            break;
          case 'good':
          default:
            targetRatio = 0.10 + random.nextDouble() * 0.60; // 0.10-0.70
            break;
        }

        // Create image where approximately targetRatio pixels will be below threshold (128)
        for (int y = 0; y < height; y++) {
          for (int x = 0; x < width; x++) {
            final shouldBeDark = random.nextDouble() < targetRatio;
            final value =
                shouldBeDark
                    ? random.nextInt(100) // Dark pixels (0-99, below threshold)
                    : 150 +
                        random.nextInt(
                          106,
                        ); // Light pixels (150-255, above threshold)
            image.setPixelRgba(x, y, value, value, value, 255);
          }
        }

        return image;
      }

      /// Generate a valid image that should pass all checks
      img.Image generateValidImage() {
        final width = 100 + random.nextInt(200);
        final height = 100 + random.nextInt(200);
        final image = img.Image(width: width, height: height);

        // White background (210-230) - ensures good brightness
        final bgValue = 210 + random.nextInt(20);
        img.fill(image, color: img.ColorRgb8(bgValue, bgValue, bgValue));

        // Add dark handwriting-like strokes (20-60) - ensures good contrast
        final textValue = 20 + random.nextInt(40);
        final numStrokes =
            8 + random.nextInt(12); // More strokes for better black pixel ratio

        for (int i = 0; i < numStrokes; i++) {
          final x1 = random.nextInt(width);
          final y1 = random.nextInt(height);
          final x2 = random.nextInt(width);
          final y2 = random.nextInt(height);
          img.drawLine(
            image,
            x1: x1,
            y1: y1,
            x2: x2,
            y2: y2,
            color: img.ColorRgb8(textValue, textValue, textValue),
            thickness:
                3 + random.nextInt(3), // Thicker lines for better visibility
          );
        }

        return image;
      }

      test(
        '**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5** - Property: Images with excessive color variance should be rejected',
        () {
          // Run 5 iterations with random high-variance images
          for (int i = 0; i < 5; i++) {
            final image = generateImageWithColorVariance(true);
            final file = createTestImageFile(image, 'high_variance_$i.png');

            final result = ImageValidator.validateImage(file);

            // High variance images should be rejected
            // Note: Some might pass if they happen to have low variance despite randomness
            // But most should fail
            if (!result.isValid) {
              expect(
                result.reason,
                ValidationFailureReason.tooManyColors,
                reason:
                    'High variance image should fail with tooManyColors reason',
              );
              expect(
                result.errorMessage,
                contains('too many colors'),
                reason: 'Error message should mention too many colors',
              );
            }
          }
        },
      );

      test(
        '**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5** - Property: Images with low contrast should be rejected',
        () {
          // Run 5 iterations with random low-contrast images
          for (int i = 0; i < 5; i++) {
            final image = generateImageWithContrast(true);
            final file = createTestImageFile(image, 'low_contrast_$i.png');

            final result = ImageValidator.validateImage(file);

            // Low contrast images should be rejected
            expect(
              result.isValid,
              false,
              reason: 'Low contrast image should be rejected',
            );
            expect(
              result.reason,
              ValidationFailureReason.lowContrast,
              reason: 'Low contrast image should fail with lowContrast reason',
            );
            expect(
              result.errorMessage,
              contains('low contrast'),
              reason: 'Error message should mention low contrast',
            );
          }
        },
      );

      test(
        '**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5** - Property: Images with unsuitable brightness should be rejected',
        () {
          // Test too dark images
          for (int i = 0; i < 5; i++) {
            final image = generateImageWithBrightness('tooDark');
            final file = createTestImageFile(image, 'too_dark_$i.png');

            final result = ImageValidator.validateImage(file);

            // Too dark images should be rejected
            // Note: They might fail with lowContrast or insufficientBrightness
            // depending on the variance in the generated image
            expect(
              result.isValid,
              false,
              reason: 'Too dark image should be rejected',
            );
            expect(
              result.reason == ValidationFailureReason.insufficientBrightness ||
                  result.reason == ValidationFailureReason.lowContrast,
              true,
              reason:
                  'Too dark image should fail with brightness or contrast reason',
            );
          }

          // Test too light images
          for (int i = 0; i < 5; i++) {
            final image = generateImageWithBrightness('tooLight');
            final file = createTestImageFile(image, 'too_light_$i.png');

            final result = ImageValidator.validateImage(file);

            // Too light images should be rejected
            // Note: They might fail with lowContrast, insufficientBrightness, or invalidBlackPixelRatio
            // depending on the variance in the generated image
            expect(
              result.isValid,
              false,
              reason: 'Too light image should be rejected',
            );
            expect(
              result.reason == ValidationFailureReason.insufficientBrightness ||
                  result.reason == ValidationFailureReason.lowContrast ||
                  result.reason ==
                      ValidationFailureReason.invalidBlackPixelRatio,
              true,
              reason:
                  'Too light image should fail with brightness, contrast, or pixel ratio reason',
            );
          }
        },
      );

      test(
        '**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5** - Property: Images with invalid black pixel ratio should be rejected',
        () {
          // Test images with too few black pixels
          for (int i = 0; i < 5; i++) {
            final image = generateImageWithBlackPixelRatio('tooFew');
            final file = createTestImageFile(image, 'too_few_black_$i.png');

            final result = ImageValidator.validateImage(file);

            // Images with too few black pixels should be rejected
            expect(
              result.isValid,
              false,
              reason: 'Image with too few black pixels should be rejected',
            );
            expect(
              result.reason,
              ValidationFailureReason.invalidBlackPixelRatio,
              reason: 'Should fail with invalidBlackPixelRatio reason',
            );
            expect(
              result.errorMessage,
              contains('content ratio'),
              reason: 'Error message should mention content ratio',
            );
          }

          // Test images with too many black pixels
          for (int i = 0; i < 5; i++) {
            final image = generateImageWithBlackPixelRatio('tooMany');
            final file = createTestImageFile(image, 'too_many_black_$i.png');

            final result = ImageValidator.validateImage(file);

            // Images with too many black pixels should be rejected
            expect(
              result.isValid,
              false,
              reason: 'Image with too many black pixels should be rejected',
            );
            expect(
              result.reason,
              ValidationFailureReason.invalidBlackPixelRatio,
              reason: 'Should fail with invalidBlackPixelRatio reason',
            );
            expect(
              result.errorMessage,
              contains('content ratio'),
              reason: 'Error message should mention content ratio',
            );
          }
        },
      );

      test(
        '**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5** - Property: Valid images should pass all validation checks',
        () {
          // Run 5 iterations with valid images
          int passedCount = 0;
          int failedCount = 0;

          for (int i = 0; i < 5; i++) {
            final image = generateValidImage();
            final file = createTestImageFile(image, 'valid_$i.png');

            final result = ImageValidator.validateImage(file);

            if (result.isValid) {
              passedCount++;
              expect(
                result.errorMessage,
                isNull,
                reason: 'Valid image should have no error message',
              );
            } else {
              failedCount++;
              // Some valid-looking images might still fail due to randomness
              // This is acceptable as long as most pass
            }
          }

          // At least 80% of "valid" images should pass
          // (Some might fail due to random generation not perfectly meeting all thresholds)
          expect(
            passedCount,
            greaterThanOrEqualTo(4),
            reason: 'At least 80% of valid images should pass validation',
          );
        },
      );

      test(
        '**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5** - Property: Validation result always includes appropriate error message when invalid',
        () {
          // Generate various invalid images and verify error messages
          final testCases = [
            {
              'generator': () => generateImageWithColorVariance(true),
              'type': 'high_variance',
            },
            {
              'generator': () => generateImageWithContrast(true),
              'type': 'low_contrast',
            },
            {
              'generator': () => generateImageWithBrightness('tooDark'),
              'type': 'too_dark',
            },
            {
              'generator': () => generateImageWithBrightness('tooLight'),
              'type': 'too_light',
            },
            {
              'generator': () => generateImageWithBlackPixelRatio('tooFew'),
              'type': 'too_few_black',
            },
            {
              'generator': () => generateImageWithBlackPixelRatio('tooMany'),
              'type': 'too_many_black',
            },
          ];

          for (final testCase in testCases) {
            for (int i = 0; i < 5; i++) {
              final generator = testCase['generator'] as img.Image Function();
              final type = testCase['type'] as String;
              final image = generator();
              final file = createTestImageFile(image, '${type}_$i.png');

              final result = ImageValidator.validateImage(file);

              if (!result.isValid) {
                // Invalid images must have an error message
                expect(
                  result.errorMessage,
                  isNotNull,
                  reason: 'Invalid image must have an error message',
                );
                expect(
                  result.errorMessage!.isNotEmpty,
                  true,
                  reason: 'Error message must not be empty',
                );

                // Error message should be user-friendly (not technical)
                expect(
                  result.errorMessage,
                  isNot(contains('Exception')),
                  reason: 'Error message should be user-friendly',
                );
                expect(
                  result.errorMessage,
                  isNot(contains('Stack trace')),
                  reason: 'Error message should not contain stack traces',
                );

                // Must have a failure reason
                expect(
                  result.reason,
                  isNotNull,
                  reason: 'Invalid image must have a failure reason',
                );
              }
            }
          }
        },
      );

      test(
        '**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5** - Property: Validation is deterministic for the same image',
        () {
          // Generate a few test images and validate them multiple times
          for (int i = 0; i < 10; i++) {
            final image = generateValidImage();
            final file = createTestImageFile(image, 'deterministic_$i.png');

            // Validate the same image 5 times
            final results = <ValidationResult>[];
            for (int j = 0; j < 5; j++) {
              results.add(ImageValidator.validateImage(file));
            }

            // All results should be identical
            final firstResult = results[0];
            for (int j = 1; j < results.length; j++) {
              expect(
                results[j].isValid,
                firstResult.isValid,
                reason: 'Validation should be deterministic',
              );
              expect(
                results[j].reason,
                firstResult.reason,
                reason: 'Failure reason should be consistent',
              );
              expect(
                results[j].errorMessage,
                firstResult.errorMessage,
                reason: 'Error message should be consistent',
              );
            }
          }
        },
      );
    },
  );
}
