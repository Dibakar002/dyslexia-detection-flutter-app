import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:image/image.dart' as img;
import 'package:dyslexia_detection_app/models/prediction_result.dart';
import 'package:dyslexia_detection_app/models/validation_result.dart';
import 'package:dyslexia_detection_app/utils/image_validator.dart';
import 'package:dyslexia_detection_app/utils/image_processor.dart';

/// Integration tests with mocked components to test complete flows
/// These tests verify the integration between components without
/// requiring actual camera, gallery, or API access
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Image Validation Integration', () {
    test('Valid image passes validation', () async {
      // Create a valid test image: white background with dark handwriting
      final image = img.Image(width: 400, height: 200);

      // Fill with white background
      img.fill(image, color: img.ColorRgb8(255, 255, 255));

      // Add some dark "handwriting" (black pixels)
      for (int y = 80; y < 120; y++) {
        for (int x = 100; x < 300; x++) {
          if ((x + y) % 3 == 0) {
            image.setPixel(x, y, img.ColorRgb8(0, 0, 0));
          }
        }
      }

      // Save to temporary file
      final tempDir = Directory.systemTemp.createTempSync();
      final imageFile = File('${tempDir.path}/test_image.jpg');
      await imageFile.writeAsBytes(img.encodeJpg(image));

      // Validate
      final result = ImageValidator.validateImage(imageFile);

      // Clean up
      await tempDir.delete(recursive: true);

      // Assert
      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('Image with too many colors fails validation', () async {
      // Create a colorful image
      final image = img.Image(width: 400, height: 200);

      // Fill with various colors
      for (int y = 0; y < 200; y++) {
        for (int x = 0; x < 400; x++) {
          image.setPixel(
            x,
            y,
            img.ColorRgb8(
              (x * 255 ~/ 400),
              (y * 255 ~/ 200),
              ((x + y) * 255 ~/ 600),
            ),
          );
        }
      }

      // Save to temporary file
      final tempDir = Directory.systemTemp.createTempSync();
      final imageFile = File('${tempDir.path}/colorful_image.jpg');
      await imageFile.writeAsBytes(img.encodeJpg(image));

      // Validate
      final result = ImageValidator.validateImage(imageFile);

      // Clean up
      await tempDir.delete(recursive: true);

      // Assert
      expect(result.isValid, isFalse);
      expect(result.errorMessage, isNotNull);
      expect(result.reason, equals(ValidationFailureReason.tooManyColors));
    });

    test('Low contrast image fails validation', () async {
      // Create a low contrast image (all gray)
      final image = img.Image(width: 400, height: 200);

      // Fill with similar gray values
      for (int y = 0; y < 200; y++) {
        for (int x = 0; x < 400; x++) {
          final gray = 120 + ((x + y) % 10);
          image.setPixel(x, y, img.ColorRgb8(gray, gray, gray));
        }
      }

      // Save to temporary file
      final tempDir = Directory.systemTemp.createTempSync();
      final imageFile = File('${tempDir.path}/low_contrast_image.jpg');
      await imageFile.writeAsBytes(img.encodeJpg(image));

      // Validate
      final result = ImageValidator.validateImage(imageFile);

      // Clean up
      await tempDir.delete(recursive: true);

      // Assert
      expect(result.isValid, isFalse);
      expect(result.errorMessage, isNotNull);
      expect(result.reason, equals(ValidationFailureReason.lowContrast));
    });
  });

  group('Image Preprocessing Integration', () {
    test('Preprocessing produces correct output format', () async {
      // Create a test image
      final image = img.Image(width: 400, height: 200);

      // Fill with white background
      img.fill(image, color: img.ColorRgb8(255, 255, 255));

      // Add some dark content
      for (int y = 80; y < 120; y++) {
        for (int x = 100; x < 300; x++) {
          if ((x + y) % 2 == 0) {
            image.setPixel(x, y, img.ColorRgb8(0, 0, 0));
          }
        }
      }

      // Save to temporary file
      final tempDir = Directory.systemTemp.createTempSync();
      final imageFile = File('${tempDir.path}/test_image.jpg');
      await imageFile.writeAsBytes(img.encodeJpg(image));

      // Preprocess
      final preprocessedBytes = await ImageProcessor.preprocessImage(imageFile);

      // Decode preprocessed image
      final preprocessed = img.decodeImage(preprocessedBytes);

      // Clean up
      await tempDir.delete(recursive: true);

      // Assert dimensions
      expect(preprocessed, isNotNull);
      expect(preprocessed!.width, equals(256));
      expect(preprocessed.height, equals(64));

      // Verify grayscale (R=G=B)
      bool isGrayscale = true;
      for (int y = 0; y < preprocessed.height; y++) {
        for (int x = 0; x < preprocessed.width; x++) {
          final pixel = preprocessed.getPixel(x, y);
          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();
          if (r != g || g != b) {
            isGrayscale = false;
            break;
          }
        }
        if (!isGrayscale) break;
      }
      expect(isGrayscale, isTrue);

      // Verify binary (only 0 or 255)
      bool isBinary = true;
      for (int y = 0; y < preprocessed.height; y++) {
        for (int x = 0; x < preprocessed.width; x++) {
          final pixel = preprocessed.getPixel(x, y);
          final value = pixel.r.toInt();
          if (value != 0 && value != 255) {
            isBinary = false;
            break;
          }
        }
        if (!isBinary) break;
      }
      expect(isBinary, isTrue);
    });

    test('Preprocessing preserves aspect ratio', () async {
      // Create a wide image (aspect ratio 2:1)
      final image = img.Image(width: 400, height: 200);
      img.fill(image, color: img.ColorRgb8(255, 255, 255));

      // Save to temporary file
      final tempDir = Directory.systemTemp.createTempSync();
      final imageFile = File('${tempDir.path}/wide_image.jpg');
      await imageFile.writeAsBytes(img.encodeJpg(image));

      // Preprocess
      final preprocessedBytes = await ImageProcessor.preprocessImage(imageFile);
      final preprocessed = img.decodeImage(preprocessedBytes);

      // Clean up
      await tempDir.delete(recursive: true);

      // Assert
      expect(preprocessed, isNotNull);
      expect(preprocessed!.width, equals(256));
      expect(preprocessed.height, equals(64));

      // The content should be scaled to fit within 64x256
      // Original aspect ratio: 400/200 = 2.0
      // Target: 256/64 = 4.0
      // So height should be the limiting factor
      // Scaled dimensions: 128x64 (preserving 2:1 ratio)
      // Then padded to 256x64

      // Check that there's padding (black pixels on sides)
      bool hasLeftPadding = true;
      for (int y = 0; y < preprocessed.height; y++) {
        final pixel = preprocessed.getPixel(0, y);
        if (pixel.r.toInt() != 0) {
          hasLeftPadding = false;
          break;
        }
      }

      bool hasRightPadding = true;
      for (int y = 0; y < preprocessed.height; y++) {
        final pixel = preprocessed.getPixel(preprocessed.width - 1, y);
        if (pixel.r.toInt() != 0) {
          hasRightPadding = false;
          break;
        }
      }

      // At least one side should have padding
      expect(hasLeftPadding || hasRightPadding, isTrue);
    });

    test('Preprocessing handles small images', () async {
      // Create a very small image
      final image = img.Image(width: 50, height: 30);
      img.fill(image, color: img.ColorRgb8(255, 255, 255));

      // Save to temporary file
      final tempDir = Directory.systemTemp.createTempSync();
      final imageFile = File('${tempDir.path}/small_image.jpg');
      await imageFile.writeAsBytes(img.encodeJpg(image));

      // Preprocess
      final preprocessedBytes = await ImageProcessor.preprocessImage(imageFile);
      final preprocessed = img.decodeImage(preprocessedBytes);

      // Clean up
      await tempDir.delete(recursive: true);

      // Assert
      expect(preprocessed, isNotNull);
      expect(preprocessed!.width, equals(256));
      expect(preprocessed.height, equals(64));
    });

    test('Preprocessing handles large images', () async {
      // Create a large image
      final image = img.Image(width: 2000, height: 1500);
      img.fill(image, color: img.ColorRgb8(255, 255, 255));

      // Add some content
      for (int y = 700; y < 800; y++) {
        for (int x = 900; x < 1100; x++) {
          image.setPixel(x, y, img.ColorRgb8(0, 0, 0));
        }
      }

      // Save to temporary file
      final tempDir = Directory.systemTemp.createTempSync();
      final imageFile = File('${tempDir.path}/large_image.jpg');
      await imageFile.writeAsBytes(img.encodeJpg(image));

      // Preprocess
      final preprocessedBytes = await ImageProcessor.preprocessImage(imageFile);
      final preprocessed = img.decodeImage(preprocessedBytes);

      // Clean up
      await tempDir.delete(recursive: true);

      // Assert
      expect(preprocessed, isNotNull);
      expect(preprocessed!.width, equals(256));
      expect(preprocessed.height, equals(64));
    });
  });

  group('Validation and Preprocessing Integration', () {
    test('Valid image passes validation and preprocessing', () async {
      // Create a valid test image
      final image = img.Image(width: 400, height: 200);
      img.fill(image, color: img.ColorRgb8(255, 255, 255));

      // Add dark handwriting
      for (int y = 80; y < 120; y++) {
        for (int x = 100; x < 300; x++) {
          if ((x + y) % 3 == 0) {
            image.setPixel(x, y, img.ColorRgb8(0, 0, 0));
          }
        }
      }

      // Save to temporary file
      final tempDir = Directory.systemTemp.createTempSync();
      final imageFile = File('${tempDir.path}/test_image.jpg');
      await imageFile.writeAsBytes(img.encodeJpg(image));

      // Validate
      final validationResult = ImageValidator.validateImage(imageFile);
      expect(validationResult.isValid, isTrue);

      // If validation passes, preprocess
      if (validationResult.isValid) {
        final preprocessedBytes = await ImageProcessor.preprocessImage(
          imageFile,
        );
        final preprocessed = img.decodeImage(preprocessedBytes);

        expect(preprocessed, isNotNull);
        expect(preprocessed!.width, equals(256));
        expect(preprocessed.height, equals(64));
      }

      // Clean up
      await tempDir.delete(recursive: true);
    });

    test('Invalid image fails validation and skips preprocessing', () async {
      // Create an invalid image (all one color)
      final image = img.Image(width: 400, height: 200);
      img.fill(image, color: img.ColorRgb8(128, 128, 128));

      // Save to temporary file
      final tempDir = Directory.systemTemp.createTempSync();
      final imageFile = File('${tempDir.path}/invalid_image.jpg');
      await imageFile.writeAsBytes(img.encodeJpg(image));

      // Validate
      final validationResult = ImageValidator.validateImage(imageFile);
      expect(validationResult.isValid, isFalse);
      expect(validationResult.errorMessage, isNotNull);

      // Should not proceed to preprocessing
      // In the app, this would show an error message to the user

      // Clean up
      await tempDir.delete(recursive: true);
    });
  });

  group('PredictionResult Model Integration', () {
    test('PredictionResult parses JSON correctly', () {
      final json = {
        'prediction': 0,
        'label': 'Non-Dyslexic',
        'confidence': 0.95,
      };

      final result = PredictionResult.fromJson(json);

      expect(result.prediction, equals(0));
      expect(result.label, equals('Non-Dyslexic'));
      expect(result.confidence, equals(0.95));
      expect(result.getResultColor(), equals(Colors.green));
      expect(result.getConfidencePercentage(), equals('95.0%'));
    });

    test('PredictionResult handles Dyslexic result', () {
      final json = {'prediction': 1, 'label': 'Dyslexic', 'confidence': 0.87};

      final result = PredictionResult.fromJson(json);

      expect(result.prediction, equals(1));
      expect(result.label, equals('Dyslexic'));
      expect(result.confidence, equals(0.87));
      expect(result.getResultColor(), equals(Colors.red));
      expect(result.getConfidencePercentage(), equals('87.0%'));
    });

    test('PredictionResult handles edge case confidences', () {
      final testCases = [
        {'prediction': 0, 'label': 'Non-Dyslexic', 'confidence': 0.0},
        {'prediction': 0, 'label': 'Non-Dyslexic', 'confidence': 0.5},
        {'prediction': 1, 'label': 'Dyslexic', 'confidence': 1.0},
      ];

      for (final testCase in testCases) {
        final result = PredictionResult.fromJson(testCase);
        expect(result.confidence, equals(testCase['confidence']));

        final expectedPercentage =
            '${((testCase['confidence'] as double) * 100).toStringAsFixed(1)}%';
        expect(result.getConfidencePercentage(), equals(expectedPercentage));
      }
    });
  });

  group('Error Handling Integration', () {
    test('ValidationResult provides specific error messages', () {
      final reasons = [
        ValidationFailureReason.tooManyColors,
        ValidationFailureReason.lowContrast,
        ValidationFailureReason.insufficientBrightness,
        ValidationFailureReason.invalidBlackPixelRatio,
      ];

      for (final reason in reasons) {
        final result = ValidationResult(
          isValid: false,
          errorMessage: 'Test error',
          reason: reason,
        );

        expect(result.isValid, isFalse);
        expect(result.errorMessage, isNotNull);
        expect(result.reason, equals(reason));
      }
    });

    test('ValidationResult for valid image has no error', () {
      final result = ValidationResult(
        isValid: true,
        errorMessage: null,
        reason: null,
      );

      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
      expect(result.reason, isNull);
    });
  });
}
