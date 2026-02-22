import 'package:flutter/material.dart';

/// Represents the prediction result from the dyslexia detection API.
///
/// Contains the classification label, confidence score, and provides
/// utility methods for display formatting and color coding.
class PredictionResult {
  /// The numeric prediction value (0 or 1)
  final int prediction;

  /// The classification label ("Dyslexic" or "Non-Dyslexic")
  final String label;

  /// The confidence score (0.0 to 1.0) corresponding to the predicted class
  final double confidence;

  PredictionResult({
    required this.prediction,
    required this.label,
    required this.confidence,
  });

  /// Creates a PredictionResult from a JSON response.
  ///
  /// Expected JSON format:
  /// ```json
  /// {
  ///   "prediction": 0,
  ///   "label": "Non-Dyslexic",
  ///   "confidence": 0.95
  /// }
  /// ```
  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      prediction: json['prediction'] as int,
      label: json['label'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  /// Returns the appropriate color for displaying the result.
  ///
  /// - Green for "Non-Dyslexic" predictions
  /// - Red for "Dyslexic" predictions
  Color getResultColor() {
    return label == "Non-Dyslexic" ? Colors.green : Colors.red;
  }

  /// Formats the confidence score as a percentage string.
  ///
  /// Returns the confidence value multiplied by 100 with one decimal place.
  /// Example: 0.95 -> "95.0%"
  String getConfidencePercentage() {
    return "${(confidence * 100).toStringAsFixed(1)}%";
  }
}
