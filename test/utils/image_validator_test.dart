import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dyslexia_detection_app/utils/image_validator.dart';
import 'package:dyslexia_detection_app/models/validation_result.dart';
import 'package:image/image.dart' as img;

/// Unit tests for ImageValidator
///
/// These tests verify specific validation scenarios with known test images
/// to ensure each validation check works correctly and returns appropriate
/// error messages.
void main() {
  group('ImageValidator', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'image_validator_unit_test_',
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

    group('Color Variance Check', () {
      test('should reject image with excessive colors (rainbow pattern)', () {
        // Arrange - Create image with truly high variance using noise
        final image = img.Image(width: 200, height: 200);
        // Create maximum variance by alternating between extremes
        for (int y = 0; y < 200; y++) {
          for (int x = 0; x < 200; x++) {
            // Create checkerboard of extreme values for maximum variance
            if ((x + y) % 2 == 0) {
              image.setPixelRgba(x, y, 0, 0, 0, 255);
            } else {
              image.setPixelRgba(x, y, 255, 255, 255, 255);
            }
          }
        }
        final file = createTestImageFile(image, 'excessive_colors.png');

        // Act
        final result = ImageValidator.validateImage(file);

        // Assert
        expect(result.isValid, false);
        expect(result.reason, ValidationFailureReason.tooManyColors);
        expect(result.errorMessage, contains('too many colors'));
        expect(
          result.errorMessage,
          contains('white paper with dark handwriting'),
        );
      });

      test('should accept image with low color variance (white paper)', () {
        // Arrange - Create image with white background and dark text
        final image = img.Image(width: 200, height: 200);
        img.fill(image, color: img.ColorRgb8(220, 220, 220));

        // Add some dark strokes (simulating handwriting)
        img.drawLine(
          image,
          x1: 50,
          y1: 50,
          x2: 150,
          y2: 50,
          color: img.ColorRgb8(30, 30, 30),
          thickness: 3,
        );
        img.drawLine(
          image,
          x1: 50,
          y1: 100,
          x2: 150,
          y2: 100,
          color: img.ColorRgb8(30, 30, 30),
          thickness: 3,
        );

        final file = createTestImageFile(image, 'low_variance.png');

        // Act
        final result = ImageValidator.validateImage(file);

        // Assert - Should pass color variance check
        // (might fail other checks, but not color variance)
        if (!result.isValid) {
          expect(
            result.reason,
            isNot(ValidationFailureReason.tooManyColors),
            reason: 'Should not fail color variance check',
          );
        }
      });
    });

    group('Contrast Check', () {
      test('should reject image with low contrast', () {
        // Arrange - Create image with values in narrow range (120-140)
        final image = img.Image(width: 200, height: 200);
        for (int y = 0; y < 200; y++) {
          for (int x = 0; x < 200; x++) {
            final value = 120 + ((x + y) % 20);
            image.setPixelRgba(x, y, value, value, value, 255);
          }
        }
        final file = createTestImageFile(image, 'low_contrast.png');

        // Act
        final result = ImageValidator.validateImage(file);

        // Assert
        expect(result.isValid, false);
        expect(result.reason, ValidationFailureReason.lowContrast);
        expect(result.errorMessage, contains('low contrast'));
        expect(result.errorMessage, contains('good lighting'));
        expect(result.errorMessage, contains('dark handwriting'));
      });

      test('should accept image with high contrast', () {
        // Arrange - Create image with distinct light and dark regions
        final image = img.Image(width: 200, height: 200);
        img.fill(image, color: img.ColorRgb8(240, 240, 240));

        // Add dark strokes with high contrast
        for (int i = 0; i < 10; i++) {
          img.drawLine(
            image,
            x1: 20 + i * 15,
            y1: 50,
            x2: 20 + i * 15,
            y2: 150,
            color: img.ColorRgb8(10, 10, 10),
            thickness: 3,
          );
        }

        final file = createTestImageFile(image, 'high_contrast.png');

        // Act
        final result = ImageValidator.validateImage(file);

        // Assert - Should pass contrast check
        if (!result.isValid) {
          expect(
            result.reason,
            isNot(ValidationFailureReason.lowContrast),
            reason: 'Should not fail contrast check',
          );
        }
      });
    });

    group('Brightness Check', () {
      test('should reject image that is too dark', () {
        // Arrange - Create very dark image (average brightness < 50)
        final image = img.Image(width: 200, height: 200);
        img.fill(image, color: img.ColorRgb8(20, 20, 20));

        // Add slightly lighter areas but still dark overall
        for (int i = 0; i < 5; i++) {
          img.drawLine(
            image,
            x1: 40 + i * 30,
            y1: 50,
            x2: 40 + i * 30,
            y2: 150,
            color: img.ColorRgb8(40, 40, 40),
            thickness: 2,
          );
        }

        final file = createTestImageFile(image, 'too_dark.png');

        // Act
        final result = ImageValidator.validateImage(file);

        // Assert
        expect(result.isValid, false);
        // Could fail with brightness or contrast
        expect(
          result.reason == ValidationFailureReason.insufficientBrightness ||
              result.reason == ValidationFailureReason.lowContrast,
          true,
        );
        if (result.reason == ValidationFailureReason.insufficientBrightness) {
          expect(result.errorMessage, contains('brightness'));
          expect(result.errorMessage, contains('proper lighting'));
        }
      });

      test('should reject image that is too bright (overexposed)', () {
        // Arrange - Create very bright image (average brightness > 240)
        final image = img.Image(width: 200, height: 200);
        img.fill(image, color: img.ColorRgb8(250, 250, 250));

        // Add slightly darker areas but still bright overall
        for (int i = 0; i < 3; i++) {
          img.drawLine(
            image,
            x1: 50 + i * 50,
            y1: 50,
            x2: 50 + i * 50,
            y2: 150,
            color: img.ColorRgb8(245, 245, 245),
            thickness: 2,
          );
        }

        final file = createTestImageFile(image, 'too_bright.png');

        // Act
        final result = ImageValidator.validateImage(file);

        // Assert
        expect(result.isValid, false);
        // Could fail with brightness, contrast, or pixel ratio
        expect(
          result.reason == ValidationFailureReason.insufficientBrightness ||
              result.reason == ValidationFailureReason.lowContrast ||
              result.reason == ValidationFailureReason.invalidBlackPixelRatio,
          true,
        );
        if (result.reason == ValidationFailureReason.insufficientBrightness) {
          expect(result.errorMessage, contains('brightness'));
          expect(result.errorMessage, contains('overexposure'));
        }
      });

      test('should accept image with good brightness', () {
        // Arrange - Create image with brightness in acceptable range (50-240)
        final image = img.Image(width: 200, height: 200);
        img.fill(image, color: img.ColorRgb8(200, 200, 200));

        // Add dark handwriting
        for (int i = 0; i < 8; i++) {
          img.drawLine(
            image,
            x1: 30 + i * 20,
            y1: 50,
            x2: 30 + i * 20,
            y2: 150,
            color: img.ColorRgb8(40, 40, 40),
            thickness: 3,
          );
        }

        final file = createTestImageFile(image, 'good_brightness.png');

        // Act
        final result = ImageValidator.validateImage(file);

        // Assert - Should pass brightness check
        if (!result.isValid) {
          expect(
            result.reason,
            isNot(ValidationFailureReason.insufficientBrightness),
            reason: 'Should not fail brightness check',
          );
        }
      });
    });

    group('Black Pixel Ratio Check', () {
      test('should reject image with too few black pixels (< 0.05)', () {
        // Arrange - Create mostly white image with very little content
        final image = img.Image(width: 200, height: 200);
        img.fill(image, color: img.ColorRgb8(230, 230, 230));

        // Add tiny amount of dark content (< 5% of pixels)
        img.drawLine(
          image,
          x1: 100,
          y1: 100,
          x2: 110,
          y2: 100,
          color: img.ColorRgb8(50, 50, 50),
          thickness: 1,
        );

        final file = createTestImageFile(image, 'too_few_black.png');

        // Act
        final result = ImageValidator.validateImage(file);

        // Assert
        expect(result.isValid, false);
        expect(result.reason, ValidationFailureReason.invalidBlackPixelRatio);
        expect(result.errorMessage, contains('content ratio'));
        expect(result.errorMessage, contains('handwriting fills frame'));
      });

      test('should reject image with too many black pixels (> 0.80)', () {
        // Arrange - Create mostly black image
        final image = img.Image(width: 200, height: 200);
        img.fill(image, color: img.ColorRgb8(30, 30, 30));

        // Add small amount of white content (< 20% of pixels)
        img.fillRect(
          image,
          x1: 80,
          y1: 80,
          x2: 120,
          y2: 120,
          color: img.ColorRgb8(200, 200, 200),
        );

        final file = createTestImageFile(image, 'too_many_black.png');

        // Act
        final result = ImageValidator.validateImage(file);

        // Assert
        expect(result.isValid, false);
        // Could fail with brightness or pixel ratio since image is very dark
        expect(
          result.reason == ValidationFailureReason.invalidBlackPixelRatio ||
              result.reason == ValidationFailureReason.insufficientBrightness,
          true,
        );
        expect(
          result.errorMessage,
          anyOf(contains('content ratio'), contains('brightness')),
        );
      });

      test('should accept image with appropriate black pixel ratio', () {
        // Arrange - Create image with ~20% black pixels (in valid range)
        final image = img.Image(width: 200, height: 200);
        img.fill(image, color: img.ColorRgb8(210, 210, 210));

        // Add handwriting-like content (approximately 20% coverage)
        for (int i = 0; i < 12; i++) {
          img.drawLine(
            image,
            x1: 20 + i * 15,
            y1: 50,
            x2: 20 + i * 15,
            y2: 150,
            color: img.ColorRgb8(40, 40, 40),
            thickness: 4,
          );
        }

        final file = createTestImageFile(image, 'good_ratio.png');

        // Act
        final result = ImageValidator.validateImage(file);

        // Assert - Should pass pixel ratio check
        if (!result.isValid) {
          expect(
            result.reason,
            isNot(ValidationFailureReason.invalidBlackPixelRatio),
            reason: 'Should not fail black pixel ratio check',
          );
        }
      });
    });

    group('Error Messages', () {
      test('should provide specific error message for each failure type', () {
        // Test each failure type has distinct error message

        // 1. Too many colors - use truly random pattern
        final colorImage = img.Image(width: 100, height: 100);
        for (int y = 0; y < 100; y++) {
          for (int x = 0; x < 100; x++) {
            final r = ((x * 17 + y * 31) % 256);
            final g = ((x * 23 + y * 41) % 256);
            final b = ((x * 29 + y * 37) % 256);
            colorImage.setPixelRgba(x, y, r, g, b, 255);
          }
        }
        final colorFile = createTestImageFile(colorImage, 'colors.png');
        final colorResult = ImageValidator.validateImage(colorFile);
        if (!colorResult.isValid) {
          expect(colorResult.errorMessage, isNotNull);
          expect(colorResult.errorMessage, contains('too many colors'));
        }

        // 2. Low contrast
        final contrastImage = img.Image(width: 100, height: 100);
        img.fill(contrastImage, color: img.ColorRgb8(128, 128, 128));
        final contrastFile = createTestImageFile(contrastImage, 'contrast.png');
        final contrastResult = ImageValidator.validateImage(contrastFile);
        expect(contrastResult.errorMessage, contains('low contrast'));

        // 3. Poor brightness
        final darkImage = img.Image(width: 100, height: 100);
        img.fill(darkImage, color: img.ColorRgb8(10, 10, 10));
        final darkFile = createTestImageFile(darkImage, 'dark.png');
        final darkResult = ImageValidator.validateImage(darkFile);
        expect(
          darkResult.errorMessage!,
          anyOf(contains('brightness'), contains('contrast')),
        );

        // 4. Invalid pixel ratio - pure white image
        final ratioImage = img.Image(width: 100, height: 100);
        img.fill(ratioImage, color: img.ColorRgb8(250, 250, 250));
        final ratioFile = createTestImageFile(ratioImage, 'ratio.png');
        final ratioResult = ImageValidator.validateImage(ratioFile);
        // Pure white might fail on contrast or pixel ratio
        expect(
          ratioResult.errorMessage,
          anyOf(contains('content ratio'), contains('contrast')),
        );
      });

      test('should provide user-friendly error messages', () {
        // Arrange - Create an invalid image
        final image = img.Image(width: 100, height: 100);
        img.fill(image, color: img.ColorRgb8(128, 128, 128));
        final file = createTestImageFile(image, 'invalid.png');

        // Act
        final result = ImageValidator.validateImage(file);

        // Assert
        expect(result.isValid, false);
        expect(result.errorMessage, isNotNull);
        expect(result.errorMessage!.isNotEmpty, true);

        // Error message should not contain technical jargon
        expect(result.errorMessage, isNot(contains('Exception')));
        expect(result.errorMessage, isNot(contains('Stack trace')));
        expect(result.errorMessage, isNot(contains('null')));

        // Error message should provide guidance
        expect(
          result.errorMessage!.length,
          greaterThan(20),
          reason: 'Error message should be descriptive',
        );
      });
    });

    group('Edge Cases', () {
      test('should handle invalid image file gracefully', () {
        // Arrange - Create a file with invalid image data
        final file = File('${tempDir.path}/invalid.png');
        file.writeAsBytesSync([0, 1, 2, 3, 4, 5]); // Invalid PNG data

        // Act
        final result = ImageValidator.validateImage(file);

        // Assert
        expect(result.isValid, false);
        expect(result.errorMessage, isNotNull);
        expect(result.errorMessage, contains('decode'));
      });

      test('should handle very small images', () {
        // Arrange - Create tiny 10x10 image
        final image = img.Image(width: 10, height: 10);
        img.fill(image, color: img.ColorRgb8(200, 200, 200));
        img.drawLine(
          image,
          x1: 2,
          y1: 2,
          x2: 8,
          y2: 8,
          color: img.ColorRgb8(50, 50, 50),
          thickness: 1,
        );
        final file = createTestImageFile(image, 'tiny.png');

        // Act
        final result = ImageValidator.validateImage(file);

        // Assert - Should process without crashing
        expect(result, isNotNull);
        expect(result.errorMessage, anyOf(isNull, isA<String>()));
      });

      test('should handle pure black image', () {
        // Arrange - Create completely black image
        final image = img.Image(width: 100, height: 100);
        img.fill(image, color: img.ColorRgb8(0, 0, 0));
        final file = createTestImageFile(image, 'black.png');

        // Act
        final result = ImageValidator.validateImage(file);

        // Assert
        expect(result.isValid, false);
        // Should fail on contrast, brightness, or pixel ratio
        expect(
          result.reason == ValidationFailureReason.lowContrast ||
              result.reason == ValidationFailureReason.insufficientBrightness ||
              result.reason == ValidationFailureReason.invalidBlackPixelRatio,
          true,
        );
      });

      test('should handle pure white image', () {
        // Arrange - Create completely white image
        final image = img.Image(width: 100, height: 100);
        img.fill(image, color: img.ColorRgb8(255, 255, 255));
        final file = createTestImageFile(image, 'white.png');

        // Act
        final result = ImageValidator.validateImage(file);

        // Assert
        expect(result.isValid, false);
        // Should fail on contrast or pixel ratio
        expect(
          result.reason == ValidationFailureReason.lowContrast ||
              result.reason == ValidationFailureReason.invalidBlackPixelRatio,
          true,
        );
      });
    });

    group('Integration', () {
      test('should validate realistic handwriting sample successfully', () {
        // Arrange - Create realistic handwriting sample with sufficient content
        final image = img.Image(width: 400, height: 300);
        img.fill(image, color: img.ColorRgb8(220, 220, 220));

        // Simulate handwriting with many thick strokes to ensure good pixel ratio
        // Create multiple rows of text-like strokes
        for (int row = 0; row < 5; row++) {
          final y = 50 + row * 50;
          for (int col = 0; col < 6; col++) {
            final x1 = 30 + col * 60;
            final x2 = x1 + 40;
            img.drawLine(
              image,
              x1: x1,
              y1: y,
              x2: x2,
              y2: y,
              color: img.ColorRgb8(30, 30, 30),
              thickness: 6,
            );
          }
        }

        final file = createTestImageFile(image, 'realistic.png');

        // Act
        final result = ImageValidator.validateImage(file);

        // Assert
        expect(result.isValid, true);
        expect(result.errorMessage, isNull);
        expect(result.reason, isNull);
      });

      test('should reject realistic photo with multiple objects', () {
        // Arrange - Simulate photo with pen, paper, and hand (high variance)
        final image = img.Image(width: 300, height: 200);

        // Background (desk)
        img.fill(image, color: img.ColorRgb8(180, 150, 120));

        // Paper area (white)
        img.fillRect(
          image,
          x1: 50,
          y1: 30,
          x2: 250,
          y2: 170,
          color: img.ColorRgb8(240, 240, 240),
        );

        // Pen (blue/black)
        img.fillRect(
          image,
          x1: 200,
          y1: 100,
          x2: 280,
          y2: 110,
          color: img.ColorRgb8(20, 40, 80),
        );

        // Hand/skin tone
        img.fillCircle(
          image,
          x: 270,
          y: 150,
          radius: 30,
          color: img.ColorRgb8(220, 180, 150),
        );

        final file = createTestImageFile(image, 'multi_object.png');

        // Act
        final result = ImageValidator.validateImage(file);

        // Assert - Should be rejected, but could fail on different checks
        expect(result.isValid, false);
        expect(
          result.reason == ValidationFailureReason.tooManyColors ||
              result.reason == ValidationFailureReason.invalidBlackPixelRatio,
          true,
          reason: 'Multi-object image should fail validation',
        );
      });
    });
  });
}
