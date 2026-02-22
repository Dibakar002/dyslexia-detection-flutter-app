import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dyslexia_detection_app/models/prediction_result.dart';

void main() {
  group('PredictionResult', () {
    group('fromJson', () {
      test('should parse valid JSON response for Non-Dyslexic prediction', () {
        // Arrange
        final json = {
          'prediction': 0,
          'label': 'Non-Dyslexic',
          'confidence': 0.95,
        };

        // Act
        final result = PredictionResult.fromJson(json);

        // Assert
        expect(result.prediction, equals(0));
        expect(result.label, equals('Non-Dyslexic'));
        expect(result.confidence, equals(0.95));
      });

      test('should parse valid JSON response for Dyslexic prediction', () {
        // Arrange
        final json = {'prediction': 1, 'label': 'Dyslexic', 'confidence': 0.87};

        // Act
        final result = PredictionResult.fromJson(json);

        // Assert
        expect(result.prediction, equals(1));
        expect(result.label, equals('Dyslexic'));
        expect(result.confidence, equals(0.87));
      });

      test('should handle confidence as integer and convert to double', () {
        // Arrange
        final json = {
          'prediction': 0,
          'label': 'Non-Dyslexic',
          'confidence': 1,
        };

        // Act
        final result = PredictionResult.fromJson(json);

        // Assert
        expect(result.confidence, equals(1.0));
        expect(result.confidence, isA<double>());
      });

      test('should handle edge case confidence values', () {
        // Test minimum confidence
        final jsonMin = {
          'prediction': 0,
          'label': 'Non-Dyslexic',
          'confidence': 0.0,
        };
        final resultMin = PredictionResult.fromJson(jsonMin);
        expect(resultMin.confidence, equals(0.0));

        // Test maximum confidence
        final jsonMax = {
          'prediction': 1,
          'label': 'Dyslexic',
          'confidence': 1.0,
        };
        final resultMax = PredictionResult.fromJson(jsonMax);
        expect(resultMax.confidence, equals(1.0));
      });
    });

    group('getResultColor', () {
      test('should return green for Non-Dyslexic label', () {
        // Arrange
        final result = PredictionResult(
          prediction: 0,
          label: 'Non-Dyslexic',
          confidence: 0.95,
        );

        // Act
        final color = result.getResultColor();

        // Assert
        expect(color, equals(Colors.green));
      });

      test('should return red for Dyslexic label', () {
        // Arrange
        final result = PredictionResult(
          prediction: 1,
          label: 'Dyslexic',
          confidence: 0.87,
        );

        // Act
        final color = result.getResultColor();

        // Assert
        expect(color, equals(Colors.red));
      });

      test('should handle case-sensitive label matching', () {
        // Test that exact string matching is used
        final result = PredictionResult(
          prediction: 0,
          label: 'Non-Dyslexic',
          confidence: 0.95,
        );

        expect(result.getResultColor(), equals(Colors.green));
      });
    });

    group('getConfidencePercentage', () {
      test('should format confidence as percentage with one decimal place', () {
        // Arrange
        final result = PredictionResult(
          prediction: 0,
          label: 'Non-Dyslexic',
          confidence: 0.95,
        );

        // Act
        final percentage = result.getConfidencePercentage();

        // Assert
        expect(percentage, equals('95.0%'));
      });

      test('should handle low confidence values', () {
        // Arrange
        final result = PredictionResult(
          prediction: 1,
          label: 'Dyslexic',
          confidence: 0.523,
        );

        // Act
        final percentage = result.getConfidencePercentage();

        // Assert
        expect(percentage, equals('52.3%'));
      });

      test('should handle high confidence values', () {
        // Arrange
        final result = PredictionResult(
          prediction: 0,
          label: 'Non-Dyslexic',
          confidence: 0.9876,
        );

        // Act
        final percentage = result.getConfidencePercentage();

        // Assert
        expect(percentage, equals('98.8%'));
      });

      test('should handle edge case confidence values', () {
        // Test 0% confidence
        final resultMin = PredictionResult(
          prediction: 0,
          label: 'Non-Dyslexic',
          confidence: 0.0,
        );
        expect(resultMin.getConfidencePercentage(), equals('0.0%'));

        // Test 100% confidence
        final resultMax = PredictionResult(
          prediction: 1,
          label: 'Dyslexic',
          confidence: 1.0,
        );
        expect(resultMax.getConfidencePercentage(), equals('100.0%'));
      });

      test('should round confidence correctly', () {
        // Test rounding down
        final resultDown = PredictionResult(
          prediction: 0,
          label: 'Non-Dyslexic',
          confidence: 0.8544,
        );
        expect(resultDown.getConfidencePercentage(), equals('85.4%'));

        // Test rounding up
        final resultUp = PredictionResult(
          prediction: 0,
          label: 'Non-Dyslexic',
          confidence: 0.8556,
        );
        expect(resultUp.getConfidencePercentage(), equals('85.6%'));
      });
    });

    group('constructor', () {
      test('should create instance with all required fields', () {
        // Act
        final result = PredictionResult(
          prediction: 1,
          label: 'Dyslexic',
          confidence: 0.75,
        );

        // Assert
        expect(result.prediction, equals(1));
        expect(result.label, equals('Dyslexic'));
        expect(result.confidence, equals(0.75));
      });
    });

    group('integration', () {
      test(
        'should correctly process complete workflow from JSON to display',
        () {
          // Arrange
          final json = {
            'prediction': 1,
            'label': 'Dyslexic',
            'confidence': 0.8765,
          };

          // Act
          final result = PredictionResult.fromJson(json);
          final color = result.getResultColor();
          final percentage = result.getConfidencePercentage();

          // Assert
          expect(result.label, equals('Dyslexic'));
          expect(color, equals(Colors.red));
          expect(percentage, equals('87.6%'));
        },
      );

      test('should handle complete Non-Dyslexic workflow', () {
        // Arrange
        final json = {
          'prediction': 0,
          'label': 'Non-Dyslexic',
          'confidence': 0.9234,
        };

        // Act
        final result = PredictionResult.fromJson(json);
        final color = result.getResultColor();
        final percentage = result.getConfidencePercentage();

        // Assert
        expect(result.label, equals('Non-Dyslexic'));
        expect(color, equals(Colors.green));
        expect(percentage, equals('92.3%'));
      });
    });
  });
}
