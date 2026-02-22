import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:dyslexia_detection_app/models/prediction_result.dart';

void main() {
  group(
    'Feature: dyslexia-detection-flutter-app, Property 15: JSON Response Parsing Extracts All Fields',
    () {
      test(
        '**Validates: Requirements 5.4, 5.5** - Random valid JSON responses are parsed correctly',
        () {
          final random = Random();

          // Run 5 iterations with random valid JSON responses
          for (int i = 0; i < 5; i++) {
            // Generate random valid values
            final prediction = random.nextInt(2); // 0 or 1
            final label = prediction == 0 ? "Non-Dyslexic" : "Dyslexic";
            final confidence = random.nextDouble(); // 0.0 to 1.0

            // Create JSON response
            final json = {
              'prediction': prediction,
              'label': label,
              'confidence': confidence,
            };

            // Parse JSON
            final result = PredictionResult.fromJson(json);

            // Verify all fields are extracted correctly
            expect(
              result.prediction,
              equals(prediction),
              reason: 'Prediction field should be extracted correctly',
            );
            expect(
              result.label,
              equals(label),
              reason: 'Label field should be extracted correctly',
            );
            expect(
              result.confidence,
              equals(confidence),
              reason: 'Confidence field should be extracted correctly',
            );
          }
        },
      );

      test(
        '**Validates: Requirements 5.4, 5.5** - JSON with integer confidence is parsed correctly',
        () {
          final random = Random();

          // Test with integer confidence values (API might return 0 or 1 as int)
          for (int i = 0; i < 5; i++) {
            final prediction = random.nextInt(2);
            final label = prediction == 0 ? "Non-Dyslexic" : "Dyslexic";
            final confidenceInt = random.nextInt(2); // 0 or 1 as integer

            final json = {
              'prediction': prediction,
              'label': label,
              'confidence': confidenceInt,
            };

            final result = PredictionResult.fromJson(json);

            expect(result.prediction, equals(prediction));
            expect(result.label, equals(label));
            expect(result.confidence, equals(confidenceInt.toDouble()));
          }
        },
      );

      test(
        '**Validates: Requirements 5.4, 5.5** - JSON with various confidence formats is parsed correctly',
        () {
          final random = Random();

          // Test with various numeric formats
          for (int i = 0; i < 5; i++) {
            final prediction = random.nextInt(2);
            final label = prediction == 0 ? "Non-Dyslexic" : "Dyslexic";

            // Generate confidence in different formats
            final confidenceValue = random.nextDouble();
            final json = {
              'prediction': prediction,
              'label': label,
              'confidence': confidenceValue,
            };

            final result = PredictionResult.fromJson(json);

            expect(result.prediction, equals(prediction));
            expect(result.label, equals(label));
            expect(result.confidence, closeTo(confidenceValue, 0.0001));
          }
        },
      );

      test(
        '**Validates: Requirements 5.4, 5.5** - Parsed result maintains label-prediction consistency',
        () {
          final random = Random();

          // Verify that the parsed result maintains consistency between prediction and label
          for (int i = 0; i < 5; i++) {
            final prediction = random.nextInt(2);
            final label = prediction == 0 ? "Non-Dyslexic" : "Dyslexic";
            final confidence = random.nextDouble();

            final json = {
              'prediction': prediction,
              'label': label,
              'confidence': confidence,
            };

            final result = PredictionResult.fromJson(json);

            // Verify consistency
            if (result.prediction == 0) {
              expect(
                result.label,
                equals("Non-Dyslexic"),
                reason: 'Prediction 0 should correspond to Non-Dyslexic label',
              );
            } else {
              expect(
                result.label,
                equals("Dyslexic"),
                reason: 'Prediction 1 should correspond to Dyslexic label',
              );
            }
          }
        },
      );

      test(
        '**Validates: Requirements 5.4, 5.5** - Confidence values are within valid range',
        () {
          final random = Random();

          // Verify confidence values are properly constrained
          for (int i = 0; i < 5; i++) {
            final prediction = random.nextInt(2);
            final label = prediction == 0 ? "Non-Dyslexic" : "Dyslexic";
            final confidence = random.nextDouble(); // Always 0.0 to 1.0

            final json = {
              'prediction': prediction,
              'label': label,
              'confidence': confidence,
            };

            final result = PredictionResult.fromJson(json);

            expect(
              result.confidence,
              greaterThanOrEqualTo(0.0),
              reason: 'Confidence should be >= 0.0',
            );
            expect(
              result.confidence,
              lessThanOrEqualTo(1.0),
              reason: 'Confidence should be <= 1.0',
            );
          }
        },
      );

      test(
        '**Validates: Requirements 5.4, 5.5** - Edge case: confidence at boundaries',
        () {
          // Test boundary values explicitly
          final testCases = [
            {'prediction': 0, 'label': 'Non-Dyslexic', 'confidence': 0.0},
            {'prediction': 0, 'label': 'Non-Dyslexic', 'confidence': 1.0},
            {'prediction': 1, 'label': 'Dyslexic', 'confidence': 0.0},
            {'prediction': 1, 'label': 'Dyslexic', 'confidence': 1.0},
            {'prediction': 0, 'label': 'Non-Dyslexic', 'confidence': 0.5},
            {'prediction': 1, 'label': 'Dyslexic', 'confidence': 0.5},
          ];

          for (final json in testCases) {
            final result = PredictionResult.fromJson(json);

            expect(result.prediction, equals(json['prediction']));
            expect(result.label, equals(json['label']));
            expect(result.confidence, equals(json['confidence']));
          }
        },
      );
    },
  );
}
