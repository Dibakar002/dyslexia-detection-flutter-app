# Requirements Document

## Introduction

This document specifies the requirements for a production-ready Flutter mobile application that enables dyslexia detection by capturing or uploading handwriting images, preprocessing them to match the expected model format, and sending them to a deployed FastAPI backend for classification. The application provides a clean, responsive user interface with proper error handling and state management.

## Glossary

- **App**: The Flutter mobile application for dyslexia detection
- **Backend_API**: The deployed FastAPI service hosted at https://dibakarb-dyslexia-backend.hf.space/predict/
- **Image_Processor**: The utility component that preprocesses images before API submission
- **API_Service**: The service layer component that handles HTTP communication with the Backend_API
- **User**: The person using the App to detect dyslexia from handwriting samples
- **Prediction_Result**: The classification output containing prediction label and confidence score
- **Preprocessed_Image**: A grayscale, contrast-enhanced, thresholded, inverted, and resized (64x256) image

## Requirements

### Requirement 1: Image Capture and Selection

**User Story:** As a User, I want to capture or select handwriting images, so that I can submit them for dyslexia detection.

#### Acceptance Criteria

1. WHEN the User taps the camera button, THE App SHALL open the device camera for image capture
2. WHEN the User taps the gallery button, THE App SHALL open the device gallery for image selection
3. WHEN the User captures or selects an image, THE App SHALL display a preview of the selected image
4. WHEN the User cancels the camera or gallery picker, THE App SHALL return to the previous state without errors
5. THE App SHALL request camera and storage permissions before accessing device features

### Requirement 2: Image Preprocessing

**User Story:** As a User, I want my handwriting images automatically preprocessed, so that they match the format expected by the detection model.

#### Acceptance Criteria

1. WHEN an image is selected, THE Image_Processor SHALL convert the image to grayscale
2. AFTER grayscale conversion, THE Image_Processor SHALL increase the image contrast
3. AFTER contrast enhancement, THE Image_Processor SHALL apply binary thresholding
4. AFTER thresholding, THE Image_Processor SHALL invert the colors to produce white handwriting on black background
5. AFTER color inversion, THE Image_Processor SHALL resize the image preserving aspect ratio, then pad with black pixels to achieve exactly 64 pixels height by 256 pixels width
6. THE Image_Processor SHALL preserve image quality during all transformation steps
7. THE Image_Processor SHALL run in an isolate using compute() to prevent UI thread blocking

### Requirement 3: Image Validation

**User Story:** As a User, I want the app to validate my images before processing, so that I receive accurate predictions and understand when my image quality is insufficient.

#### Acceptance Criteria

1. BEFORE preprocessing, THE Image_Processor SHALL check if the image has excessive color variance and reject images with too many colors
2. BEFORE preprocessing, THE Image_Processor SHALL check if the image has sufficient contrast and reject images with very low contrast
3. BEFORE preprocessing, THE Image_Processor SHALL check if the image meets minimum brightness thresholds
4. BEFORE preprocessing, THE Image_Processor SHALL analyze the percentage of black pixels after thresholding and reject images where the percentage is too high or too low
5. WHEN an image fails validation, THE App SHALL display a specific error message explaining why the image was rejected
6. WHEN an image fails validation, THE App SHALL prompt the User to capture or select a different image

### Requirement 4: User Instructions

**User Story:** As a User, I want clear instructions before capturing images, so that I understand how to provide a quality handwriting sample for accurate detection.

#### Acceptance Criteria

1. WHEN the User taps the camera or gallery button, THE App SHALL display an instruction modal before opening the picker
2. THE instruction modal SHALL list requirements: only white paper visible, no pen or objects in frame, good lighting, dark handwriting, entire text visible
3. THE instruction modal SHALL require the User to tap "I Understand" before proceeding to camera or gallery
4. THE instruction modal SHALL include a visual example of acceptable vs unacceptable images
5. THE User SHALL NOT be able to bypass the instruction modal on first use of each session

### Requirement 5: Backend API Communication

**User Story:** As a User, I want the app to communicate with the backend API, so that I can receive dyslexia detection results.

#### Acceptance Criteria

1. WHEN the User taps the predict button, THE API_Service SHALL send the Preprocessed_Image to the Backend_API via multipart/form-data POST request
2. THE API_Service SHALL use the field name "file" for the image in the multipart request
3. THE API_Service SHALL send requests to the endpoint https://dibakarb-dyslexia-backend.hf.space/predict/
4. WHEN the Backend_API responds, THE API_Service SHALL parse the JSON response containing prediction, label, and confidence fields
5. THE API_Service SHALL return the Prediction_Result to the presentation layer
6. WHEN a request takes longer than 5 seconds, THE App SHALL display a message "Waking up server..." to inform the User about cold start delays

### Requirement 6: Result Display

**User Story:** As a User, I want to see the detection results clearly, so that I can understand the dyslexia classification.

#### Acceptance Criteria

1. WHEN a Prediction_Result is received, THE App SHALL display the prediction label (Dyslexic or Non-Dyslexic)
2. WHEN a Prediction_Result is received, THE App SHALL display the confidence score as a percentage
3. THE confidence value displayed SHALL correspond to the predicted class probability
4. WHEN the label is "Non-Dyslexic", THE App SHALL use green color coding for the result display
5. WHEN the label is "Dyslexic", THE App SHALL use red color coding for the result display
6. WHEN displaying results, THE App SHALL animate the result container with a fade-in effect
7. THE App SHALL display results in a card-style container with proper spacing and padding

### Requirement 7: Loading State Management

**User Story:** As a User, I want to see loading indicators during processing, so that I know the app is working.

#### Acceptance Criteria

1. WHEN the predict button is tapped, THE App SHALL display a circular progress indicator
2. WHILE the API request is in progress, THE App SHALL disable the predict button
3. WHILE the API request is in progress, THE App SHALL prevent additional API calls
4. WHEN the API response is received or an error occurs, THE App SHALL hide the loading indicator
5. WHEN the API response is received or an error occurs, THE App SHALL re-enable the predict button

### Requirement 8: Error Handling

**User Story:** As a User, I want clear error messages when something goes wrong, so that I understand what happened and can take corrective action.

#### Acceptance Criteria

1. IF no internet connection is available, THEN THE App SHALL display a user-friendly message indicating network unavailability
2. IF the Backend_API times out, THEN THE App SHALL display a timeout error message
3. IF the Backend_API returns a 500 server error, THEN THE App SHALL display a server error message
4. IF an invalid image is selected, THEN THE App SHALL display an invalid image error message
5. IF any API error occurs, THEN THE App SHALL log the error details for debugging purposes
6. THE App SHALL handle all errors gracefully without crashing

### Requirement 9: Responsive User Interface

**User Story:** As a User, I want the app to work properly on different screen sizes, so that I can use it on any device.

#### Acceptance Criteria

1. THE App SHALL adapt its layout to different screen sizes using MediaQuery and LayoutBuilder
2. THE App SHALL use Expanded and Flexible widgets to prevent RenderFlex overflow errors
3. WHERE scrollable content is needed, THE App SHALL use SingleChildScrollView
4. THE App SHALL avoid fixed heights unless absolutely required for specific UI elements
5. THE App SHALL work correctly in portrait orientation on phones and tablets
6. THE App SHALL prevent pixel overflow errors on all supported screen sizes

### Requirement 10: Application Architecture

**User Story:** As a developer, I want clean architecture separation, so that the codebase is maintainable and scalable.

#### Acceptance Criteria

1. THE App SHALL separate UI components into a dedicated presentation layer
2. THE App SHALL implement API communication in a dedicated API_Service module
3. THE App SHALL implement image preprocessing in a dedicated Image_Processor utility module
4. THE App SHALL use Provider or setState for state management
5. THE App SHALL organize code into separate files: home_screen.dart, api_service.dart, and image_processor.dart
6. THE App SHALL NOT contain all implementation code in main.dart

### Requirement 11: Visual Design

**User Story:** As a User, I want a clean and professional interface, so that the app feels trustworthy for healthcare use.

#### Acceptance Criteria

1. THE App SHALL use a modern, minimal design aesthetic
2. THE App SHALL apply a professional academic healthcare theme
3. THE App SHALL use rounded buttons for all interactive elements
4. THE App SHALL apply proper spacing and padding throughout the interface
5. THE App SHALL use subtle color coding for result indication
6. THE App SHALL maintain visual consistency across all screens

### Requirement 12: Platform Configuration

**User Story:** As a developer, I want proper platform permissions configured, so that the app can access device features.

#### Acceptance Criteria

1. THE App SHALL declare camera permissions in the Android manifest
2. THE App SHALL declare storage/photo library permissions in the Android manifest
3. THE App SHALL include all required dependencies in pubspec.yaml (http, image_picker, image, provider)
4. THE App SHALL compile without errors on Android platform
5. THE App SHALL handle permission denial gracefully with appropriate user messaging

### Requirement 13: Non-Functional Requirements

**User Story:** As a User, I want the app to perform efficiently, so that I have a smooth experience.

#### Acceptance Criteria

1. THE App SHALL respond to prediction requests in less than 5 seconds, excluding API cold start time
2. THE App SHALL maintain memory usage below 150MB during normal operation
3. THE Image_Processor SHALL complete preprocessing in less than 1 second on mid-range devices
4. THE App SHALL remain responsive during all processing operations
5. THE App SHALL not freeze or block the UI thread during image processing or API calls

### Requirement 14: System Limitations and Constraints

**User Story:** As a User, I want to understand the system's limitations, so that I can use it appropriately.

#### Acceptance Criteria

1. THE App documentation SHALL state that the model is not robust to multiple objects in the frame
2. THE App documentation SHALL state that the model requires white paper backgrounds
3. THE App documentation SHALL state that the model is sensitive to shadows and perspective distortion
4. THE App documentation SHALL state that the model requires clean handwriting samples
5. THE App SHALL assume the User provides appropriate handwriting samples after viewing instructions
