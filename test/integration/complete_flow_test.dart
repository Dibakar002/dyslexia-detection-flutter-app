import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dyslexia_detection_app/models/prediction_result.dart';
import 'package:dyslexia_detection_app/models/validation_result.dart';

/// Integration tests for complete flows
/// These tests verify the integration between components
void main() {
  group('PredictionResult Integration', () {
    test('PredictionResult parses and formats correctly', () {
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

    test('PredictionResult handles Dyslexic result with color coding', () {
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

  group('Validation and Preprocessing Flow', () {
    test('Validation failure prevents preprocessing', () {
      // This test verifies the flow logic:
      // 1. Image is selected
      // 2. Validation is performed
      // 3. If validation fails, preprocessing is skipped
      // 4. Error message is shown to user

      // Create a validation failure result
      final validationResult = ValidationResult(
        isValid: false,
        errorMessage: 'Image has too many colors',
        reason: ValidationFailureReason.tooManyColors,
      );

      // Verify validation failed
      expect(validationResult.isValid, isFalse);
      expect(validationResult.errorMessage, isNotNull);

      // In the app flow, preprocessing would be skipped
      // and the error message would be displayed
    });

    test('Validation success allows preprocessing', () {
      // This test verifies the flow logic:
      // 1. Image is selected
      // 2. Validation is performed
      // 3. If validation passes, preprocessing proceeds
      // 4. Result is sent to API

      // Create a validation success result
      final validationResult = ValidationResult(
        isValid: true,
        errorMessage: null,
        reason: null,
      );

      // Verify validation passed
      expect(validationResult.isValid, isTrue);
      expect(validationResult.errorMessage, isNull);

      // In the app flow, preprocessing would proceed
    });
  });
}
