/// Represents the reasons why image validation might fail.
///
/// Each reason corresponds to a specific validation check performed
/// before image preprocessing.
enum ValidationFailureReason {
  /// Image contains too many colors (not primarily white paper with dark handwriting)
  tooManyColors,

  /// Image has insufficient contrast between handwriting and background
  lowContrast,

  /// Image brightness is outside acceptable range (too dark or overexposed)
  insufficientBrightness,

  /// The ratio of black pixels after thresholding is unsuitable
  /// (either too high or too low)
  invalidBlackPixelRatio,
}

/// Represents the result of image validation checks.
///
/// Before preprocessing, images are validated to ensure they meet
/// quality requirements for accurate dyslexia detection. This class
/// encapsulates the validation outcome and provides specific error
/// information when validation fails.
class ValidationResult {
  /// Whether the image passed all validation checks
  final bool isValid;

  /// Human-readable error message explaining why validation failed
  /// (null if validation passed)
  final String? errorMessage;

  /// The specific reason for validation failure
  /// (null if validation passed)
  final ValidationFailureReason? reason;

  ValidationResult({required this.isValid, this.errorMessage, this.reason});

  /// Creates a successful validation result.
  ///
  /// Use this factory when an image passes all validation checks.
  factory ValidationResult.success() {
    return ValidationResult(isValid: true, errorMessage: null, reason: null);
  }

  /// Creates a failed validation result with specific error details.
  ///
  /// Use this factory when an image fails a validation check.
  ///
  /// Parameters:
  /// - [reason]: The specific validation check that failed
  /// - [errorMessage]: A user-friendly explanation of the failure
  factory ValidationResult.failure({
    required ValidationFailureReason reason,
    required String errorMessage,
  }) {
    return ValidationResult(
      isValid: false,
      errorMessage: errorMessage,
      reason: reason,
    );
  }
}
