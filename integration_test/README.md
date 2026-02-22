# Integration Tests

This directory contains integration tests for the Dyslexia Detection Flutter App.

## Test Files

### 1. `app_integration_test.dart`
Basic integration tests that verify the app structure and UI elements without requiring device-specific features.

**Tests:**
- Complete prediction flow structure
- UI elements presence and styling
- Validation failure recovery flow
- Error recovery flows
- Permission request flows
- Responsive layout on different screen sizes
- Theme and styling consistency
- Loading state management
- Cold start message handling

### 2. `mocked_flow_test.dart`
Comprehensive integration tests with mocked components that test the complete data flow without requiring actual camera, gallery, or API access.

**Tests:**
- Image validation integration (valid/invalid images)
- Image preprocessing integration (format, dimensions, aspect ratio)
- Validation + preprocessing integration
- PredictionResult model integration
- Error handling integration

## Running Integration Tests

### Option 1: Run as Unit Tests (No Device Required)
The `mocked_flow_test.dart` can be run as regular unit tests since it doesn't require device features:

```bash
flutter test integration_test/mocked_flow_test.dart
```

### Option 2: Run on Device/Emulator (Full Integration)
For full integration tests that interact with the UI:

```bash
# Start an emulator or connect a device first
flutter emulators --launch <emulator_id>

# Run integration tests
flutter test integration_test/app_integration_test.dart --device-id=<device_id>
```

### Option 3: Run All Tests
To run all tests including integration tests:

```bash
flutter test
```

## Test Coverage

These integration tests validate:

**Requirements Coverage:**
- 1.1, 1.2, 1.3: Image capture and selection
- 3.5, 3.6: Image validation and error handling
- 4.1: Instruction modal flow
- 5.1: API communication structure
- 6.1: Result display
- 8.6: Error recovery
- 9.5, 9.6: Responsive layout
- 11.1-11.6: Visual design and styling

## Notes

- Integration tests in `app_integration_test.dart` verify UI structure but don't fully test flows that require dependency injection (camera, gallery, API)
- `mocked_flow_test.dart` provides comprehensive testing of the data flow and business logic
- For full end-to-end testing with real camera/gallery/API, the app would need dependency injection refactoring
- Current tests provide good coverage of the integration between components while remaining maintainable

## Future Enhancements

To enable full end-to-end integration testing:
1. Refactor HomeScreen to accept injected dependencies (ImagePicker, ApiService)
2. Create test doubles for ImagePicker and ApiService
3. Add integration tests that simulate complete user flows with mocked dependencies
4. Add performance testing for preprocessing and API calls
5. Add accessibility testing
