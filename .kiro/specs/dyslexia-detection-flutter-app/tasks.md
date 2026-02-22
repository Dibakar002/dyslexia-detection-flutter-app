# Implementation Plan: Dyslexia Detection Flutter App

## Overview

This plan implements a production-ready Flutter mobile application for dyslexia detection through handwriting analysis. The implementation follows a layered architecture with clear separation between presentation, service, and utility layers. Tasks are organized to build incrementally, validating core functionality early through code and tests.

## Tasks

- [x] 1. Set up Flutter project structure and dependencies
  - Initialize Flutter project with proper package name
  - Configure pubspec.yaml with required dependencies: http, image_picker, image, provider
  - Configure Android manifest with camera and storage permissions
  - Create directory structure: lib/screens/, lib/services/, lib/utils/, lib/models/, lib/widgets/
  - Set up basic main.dart with MaterialApp
  - _Requirements: 10.5, 10.6, 12.1, 12.2, 12.3_

- [x] 2. Implement data models
  - [x] 2.1 Create PredictionResult model with JSON parsing
    - Implement PredictionResult class with prediction, label, and confidence fields
    - Add fromJson factory constructor for API response parsing
    - Add getResultColor() method for color-coded display (green for Non-Dyslexic, red for Dyslexic)
    - Add getConfidencePercentage() method to format confidence as percentage
    - _Requirements: 5.4, 5.5, 6.1, 6.2, 6.3, 6.4, 6.5_

  - [x] 2.2 Write unit tests for PredictionResult model
    - Test JSON parsing with valid response payloads
    - Test color mapping for both labels
    - Test confidence percentage formatting
    - _Requirements: 6.2, 6.4, 6.5_

  - [x] 2.3 Create ValidationResult model
    - Implement ValidationResult class with isValid, errorMessage, and reason fields
    - Define ValidationFailureReason enum (tooManyColors, lowContrast, insufficientBrightness, invalidBlackPixelRatio)
    - _Requirements: 3.5, 3.6_

- [x] 3. Implement image validation utility
  - [x] 3.1 Create ImageValidator class with validation logic
    - Implement validateImage() static method
    - Add color variance check to reject images with excessive colors
    - Add contrast check to reject low contrast images
    - Add brightness check to validate lighting conditions
    - Add black pixel ratio check after simulated thresholding
    - Return ValidationResult with specific error messages for each failure type
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

  - [x] 3.2 Write property test for image validation
    - **Property 5: Image Validation Rejects Unsuitable Images**
    - **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5**
    - Generate random images with varying characteristics
    - Verify correct accept/reject decisions based on validation rules

  - [x] 3.3 Write unit tests for ImageValidator
    - Test validation with images having excessive colors
    - Test validation with low contrast images
    - Test validation with poor brightness
    - Test validation with invalid pixel ratios
    - Test specific error messages for each failure type
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 4. Implement image preprocessing pipeline
  - [x] 4.1 Create ImageProcessor class with preprocessing methods
    - Implement preprocessImage() method that orchestrates the 5-step pipeline
    - Implement grayscale conversion using luminosity method (0.299*R + 0.587*G + 0.114*B)
    - Implement contrast enhancement with factor 1.5
    - Implement binary thresholding at threshold 128
    - Implement color inversion (255 - pixel value)
    - Implement aspect-ratio-preserving resize with black padding to 64x256
    - Use compute() to run preprocessing in isolate
    - Return Uint8List of preprocessed image bytes
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_

  - [x] 4.2 Write property test for grayscale conversion
    - **Property 6: Grayscale Conversion Produces Monochrome Output**
    - **Validates: Requirements 2.1**
    - Generate random color images
    - Verify R=G=B for all pixels after conversion

  - [x] 4.3 Write property test for contrast enhancement
    - **Property 7: Contrast Enhancement Increases Dynamic Range**
    - **Validates: Requirements 2.2**
    - Generate random grayscale images
    - Verify increased standard deviation after enhancement

  - [x] 4.4 Write property test for binary thresholding
    - **Property 8: Binary Thresholding Produces Pure Black and White**
    - **Validates: Requirements 2.3**
    - Generate random images
    - Verify all pixels are 0 or 255 after thresholding

  - [x] 4.5 Write property test for color inversion
    - **Property 9: Color Inversion is Bijective**
    - **Validates: Requirements 2.4**
    - Generate random binary images
    - Verify invert(invert(image)) = image

  - [x] 4.6 Write property test for aspect ratio preservation
    - **Property 10: Resize Preserves Aspect Ratio and Produces Exact Dimensions**
    - **Validates: Requirements 2.5**
    - Generate random image dimensions
    - Verify output is exactly 64x256 and aspect ratio is preserved in non-padded content

  - [x] 4.7 Write property test for complete preprocessing pipeline
    - **Property 12: Preprocessing Pipeline Output Format**
    - **Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5**
    - Generate random input images
    - Verify output is 64x256, grayscale, binary, and inverted

  - [x] 4.8 Write unit tests for ImageProcessor
    - Test each preprocessing step with sample images
    - Test aspect ratio preservation with known dimensions (e.g., 1000x400 → 64x160 → 64x256)
    - Test edge cases: very small images, very large images, pure black/white images
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 5. Checkpoint - Ensure preprocessing tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Implement API service layer
  - [x] 6.1 Create ApiService class with prediction method
    - Define baseUrl constant: https://dibakarb-dyslexia-backend.hf.space
    - Define timeout constant: 60 seconds
    - Define coldStartThreshold constant: 5 seconds
    - Implement predictDyslexia() method with onColdStart callback parameter
    - Create MultipartRequest with POST method to /predict/ endpoint
    - Add image bytes as "file" field with filename "handwriting.jpg"
    - Implement cold start detection: trigger callback after 5 seconds if no response
    - Parse JSON response and return PredictionResult
    - Implement error classification for network, timeout, server, and client errors
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 8.1, 8.2, 8.3_

  - [x] 6.2 Write property test for JSON response parsing
    - **Property 15: JSON Response Parsing Extracts All Fields**
    - **Validates: Requirements 5.4, 5.5**
    - Generate random valid JSON responses
    - Verify successful extraction of all fields

  - [x] 6.3 Write unit tests for ApiService
    - Test API request construction with sample images
    - Test JSON parsing with known response payloads
    - Test cold start callback triggering after 5 seconds
    - Test error handling for specific HTTP status codes (404, 500, 503)
    - Test timeout handling with 60-second threshold
    - Use mocks for HTTP client
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.6, 8.1, 8.2, 8.3_

- [x] 7. Implement instruction modal widget
  - [x] 7.1 Create InstructionModal widget
    - Create modal dialog with semi-transparent background
    - Add title "Image Capture Guidelines"
    - Add instruction list with checkmarks: white paper only, no objects, good lighting, dark handwriting, entire text visible
    - Add visual examples section (placeholder for good vs bad images)
    - Add "I Understand" primary action button
    - Make modal non-dismissible without button tap
    - _Requirements: 4.1, 4.2, 4.3, 4.4_

  - [x] 7.2 Write widget tests for InstructionModal
    - Test modal display and content rendering
    - Test "I Understand" button functionality
    - Test non-dismissible behavior
    - _Requirements: 4.1, 4.2, 4.3_

- [x] 8. Implement home screen with state management
  - [x] 8.1 Create HomeScreen widget with state variables
    - Create stateful widget HomeScreen
    - Add state variables: selectedImage, preprocessedImage, isLoading, showColdStartMessage, predictionLabel, confidence, errorMessage, hasSeenInstructions
    - Implement AppBar with title "Dyslexia Detection"
    - Create image preview container with placeholder
    - Add action buttons row: Camera, Gallery, Predict
    - Add loading indicator overlay
    - Add cold start message display
    - Add result card with color-coded label and confidence
    - Use SingleChildScrollView to prevent overflow
    - Use MediaQuery for responsive sizing
    - _Requirements: 1.3, 6.1, 6.2, 6.4, 6.5, 6.7, 7.1, 9.1, 9.2, 9.3, 9.5, 9.6, 10.1_

  - [x] 8.2 Implement instruction modal flow
    - Add _showInstructionModal() method
    - Track hasSeenInstructions per session
    - Show modal before first camera/gallery access
    - Proceed to picker only after "I Understand" tap
    - _Requirements: 4.1, 4.2, 4.3, 4.5_

  - [x] 8.3 Implement image selection methods
    - Add _pickImageFromCamera() method with permission handling
    - Add _pickImageFromGallery() method with permission handling
    - Call _showInstructionModal() before opening picker
    - Implement _handleImageSelection() to validate and update state
    - Handle picker cancellation gracefully
    - Display selected image in preview container
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 12.5_

  - [x] 8.4 Implement prediction orchestration
    - Add _predictDyslexia() method
    - Set loading state and disable predict button
    - Call ImageValidator.validateImage() before preprocessing
    - Display validation errors if image fails checks
    - Call ImageProcessor.preprocessImage() in isolate
    - Call ApiService.predictDyslexia() with cold start callback
    - Display cold start message after 5 seconds
    - Update UI with prediction results
    - Clear loading state on completion or error
    - _Requirements: 3.5, 3.6, 5.1, 5.6, 7.1, 7.2, 7.3, 7.4, 7.5_

  - [x] 8.5 Implement result display with animation
    - Add _displayResult() method
    - Display prediction label and confidence percentage
    - Apply color coding: green for Non-Dyslexic, red for Dyslexic
    - Animate result card with fade-in effect
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

  - [x] 8.6 Implement error handling and classification
    - Add _handleError() method
    - Classify errors: network, timeout, server, client, validation, permission, unknown
    - Display user-friendly error messages via SnackBar
    - Log error details for debugging
    - Allow retry after errors
    - Preserve selected image after errors
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

  - [x] 8.7 Write property tests for state management
    - **Property 2: Image Selection Updates Preview State**
    - **Validates: Requirements 1.3**
    - Generate random images, verify state update
    - **Property 3: Picker Cancellation Preserves State**
    - **Validates: Requirements 1.4**
    - Generate random states, verify preservation
    - **Property 21: Loading State Activation on Predict**
    - **Validates: Requirements 7.1, 7.2, 7.3**
    - Verify all loading flags set simultaneously
    - **Property 22: Loading State Deactivation on Completion**
    - **Validates: Requirements 7.4, 7.5**
    - Verify flags cleared on completion

  - [x] 8.8 Write widget tests for HomeScreen
    - Test camera button opens instruction modal first
    - Test gallery button opens instruction modal first
    - Test image preview updates after selection
    - Test predict button triggers loading indicator
    - Test cold start message displays after 5 seconds
    - Test result display with color coding
    - Test error message display
    - Test layout responsiveness on various screen sizes
    - _Requirements: 1.1, 1.2, 1.3, 4.1, 6.4, 6.5, 7.1, 9.5, 9.6_

- [x] 9. Checkpoint - Ensure all component tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 10. Apply visual design and styling
  - [x] 10.1 Implement professional theme and styling
    - Define color scheme with primary, secondary, and accent colors
    - Apply rounded corners to all buttons (border radius > 0)
    - Add proper spacing and padding throughout UI
    - Style result card with elevation and rounded corners
    - Apply subtle color coding for results
    - Ensure visual consistency across all components
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.6_

  - [x] 10.2 Write widget tests for styling
    - Test button styling consistency (rounded corners)
    - Test color scheme application
    - Test spacing and padding
    - _Requirements: 11.3_

- [x] 11. Integration and final wiring
  - [x] 11.1 Wire all components together in main.dart
    - Import all necessary modules
    - Set up MaterialApp with theme
    - Set HomeScreen as home widget
    - Verify all imports and dependencies resolve
    - _Requirements: 10.1, 10.2, 10.3, 10.4_

  - [x] 11.2 Write integration tests for complete flows
    - Test complete prediction flow from instruction modal to result display
    - Test validation failure recovery flow
    - Test error recovery flows
    - Test permission request flows
    - Use mocks for camera, gallery, and API
    - _Requirements: 1.1, 1.2, 1.3, 3.5, 3.6, 4.1, 5.1, 6.1, 8.6_

- [x] 12. Performance validation and optimization
  - [x] 12.1 Verify performance targets
    - Test preprocessing completes in < 1 second on mid-range device
    - Verify memory usage stays below 150MB during operation
    - Confirm UI remains responsive during processing (no frame drops)
    - Verify isolate usage prevents UI thread blocking
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_

  - [x] 12.2 Write property test for UI responsiveness
    - **Property 29: UI Responsiveness During Processing**
    - **Validates: Requirements 13.4, 13.5**
    - Verify UI remains responsive during operations

- [x] 13. Final checkpoint - Ensure all tests pass and app is production-ready
  - Run all unit tests, property tests, widget tests, and integration tests
  - Verify app compiles without errors on Android
  - Test on multiple screen sizes and devices
  - Ensure all requirements are met
  - Ask the user if questions arise or if ready for deployment

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties from the design document
- Unit tests validate specific examples and edge cases
- Widget tests validate UI components and user interactions
- Integration tests validate complete user flows
- All preprocessing runs in isolates to prevent UI blocking
- Cold start handling manages user expectations for serverless deployment
- Image validation ensures model receives appropriate inputs
- Error handling provides clear, actionable feedback to users
