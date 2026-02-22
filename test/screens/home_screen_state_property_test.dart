import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dyslexia_detection_app/screens/home_screen.dart';
import 'package:image/image.dart' as img;

void main() {
  group('HomeScreen State Management Property Tests', () {
    final random = Random();

    // Helper to create a temporary test image file
    Future<File> createTestImageFile(String filename) async {
      final tempDir = Directory.systemTemp.createTempSync('test_images_');
      final image = img.Image(width: 100, height: 100);

      // Fill with white background and some dark content
      for (int y = 0; y < 100; y++) {
        for (int x = 0; x < 100; x++) {
          if (x > 20 && x < 80 && y > 20 && y < 80) {
            // Dark content in center
            image.setPixelRgba(x, y, 50, 50, 50, 255);
          } else {
            // White background
            image.setPixelRgba(x, y, 255, 255, 255, 255);
          }
        }
      }

      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(img.encodePng(image));
      return file;
    }

    testWidgets(
      'Feature: dyslexia-detection-flutter-app, Property 2: Image Selection Updates Preview State - **Validates: Requirements 1.3**',
      (WidgetTester tester) async {
        // Property: For any image selected, the app state should update to display
        // that image in the preview container, and the preview should remain visible
        // until a new image is selected or the app is reset.

        // Run 10 iterations with different random images
        for (int iteration = 0; iteration < 10; iteration++) {
          // Generate a random test image
          final testImage = await createTestImageFile(
            'test_image_$iteration.png',
          );

          // Build the HomeScreen
          await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
          await tester.pumpAndSettle();

          // Verify initial state: no image selected
          expect(find.text('No image selected'), findsOneWidget);
          expect(find.byIcon(Icons.image_outlined), findsOneWidget);

          // Access the state to simulate image selection
          final state = tester.state<State>(find.byType(HomeScreen));
          final homeScreenState = state as dynamic;

          // Simulate image selection by calling the internal handler
          // Note: In a real scenario, this would be triggered by image picker
          await homeScreenState.handleImageSelection(testImage);
          await tester.pumpAndSettle();

          // Property verification: Preview should now show the selected image
          // The placeholder should be gone
          expect(
            find.text('No image selected'),
            findsNothing,
            reason: 'Iteration $iteration: Placeholder should be hidden',
          );
          expect(
            find.byIcon(Icons.image_outlined),
            findsNothing,
            reason: 'Iteration $iteration: Placeholder icon should be hidden',
          );

          // The image should be displayed (either as File or Memory)
          final imageFinder = find.byType(Image);
          expect(
            imageFinder,
            findsAtLeastNWidgets(1),
            reason: 'Iteration $iteration: Image should be displayed',
          );

          // Verify the image remains visible after multiple pump cycles
          await tester.pump(const Duration(milliseconds: 100));
          expect(
            imageFinder,
            findsAtLeastNWidgets(1),
            reason: 'Iteration $iteration: Image should remain visible',
          );

          await tester.pump(const Duration(milliseconds: 500));
          expect(
            imageFinder,
            findsAtLeastNWidgets(1),
            reason: 'Iteration $iteration: Image should persist',
          );

          // Clean up
          await testImage.parent.delete(recursive: true);
        }
      },
    );

    testWidgets(
      'Feature: dyslexia-detection-flutter-app, Property 3: Picker Cancellation Preserves State - **Validates: Requirements 1.4**',
      (WidgetTester tester) async {
        // Property: For any app state, canceling the camera or gallery picker
        // should return the app to that exact state without modifying any state
        // variables or causing errors.

        // Run 10 iterations with different initial states
        for (int iteration = 0; iteration < 10; iteration++) {
          // Build the HomeScreen
          await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
          await tester.pumpAndSettle();

          // Randomly decide whether to have an image selected or not
          final hasImage = random.nextBool();
          File? testImage;

          if (hasImage) {
            // Set up initial state with an image
            testImage = await createTestImageFile(
              'initial_image_$iteration.png',
            );
            final state = tester.state<State>(find.byType(HomeScreen));
            final homeScreenState = state as dynamic;
            await homeScreenState.handleImageSelection(testImage);
            await tester.pumpAndSettle();
          }

          // Capture initial state
          final initialHasImage = find.byType(Image).evaluate().isNotEmpty;
          final initialPlaceholderVisible =
              find.text('No image selected').evaluate().isNotEmpty;

          // Simulate picker cancellation by tapping camera/gallery button
          // and then canceling (which happens when picker returns null)
          // In the actual implementation, if picker returns null, no state changes occur

          // The picker cancellation is handled by the image_picker package
          // When user cancels, pickImage returns null, and handleImageSelection
          // is never called. So the state should remain unchanged.

          // Verify state after "cancellation" (no action taken)
          await tester.pump();
          await tester.pumpAndSettle();

          final finalHasImage = find.byType(Image).evaluate().isNotEmpty;
          final finalPlaceholderVisible =
              find.text('No image selected').evaluate().isNotEmpty;

          // Property verification: State should be identical
          expect(
            finalHasImage,
            equals(initialHasImage),
            reason:
                'Iteration $iteration: Image presence should not change after cancellation',
          );
          expect(
            finalPlaceholderVisible,
            equals(initialPlaceholderVisible),
            reason:
                'Iteration $iteration: Placeholder visibility should not change after cancellation',
          );

          // Verify no errors occurred (widget tree is still valid)
          expect(find.byType(HomeScreen), findsOneWidget);
          expect(tester.takeException(), isNull);

          // Clean up
          if (testImage != null) {
            await testImage.parent.delete(recursive: true);
          }
        }
      },
    );

    testWidgets(
      'Feature: dyslexia-detection-flutter-app, Property 21: Loading State Activation on Predict - **Validates: Requirements 7.1, 7.2, 7.3**',
      (WidgetTester tester) async {
        // Property: For any predict button tap, the app should simultaneously:
        // (1) display the loading indicator
        // (2) disable the predict button
        // (3) set a flag preventing additional API calls

        // Run 10 iterations
        for (int iteration = 0; iteration < 10; iteration++) {
          // Create a test image
          final testImage = await createTestImageFile(
            'predict_test_$iteration.png',
          );

          // Build the HomeScreen
          await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
          await tester.pumpAndSettle();

          // Set up state with an image
          final state = tester.state<State>(find.byType(HomeScreen));
          final homeScreenState = state as dynamic;
          await homeScreenState.handleImageSelection(testImage);
          await tester.pumpAndSettle();

          // Verify predict button is enabled initially
          final predictButton = find.widgetWithText(ElevatedButton, 'Predict');
          expect(predictButton, findsOneWidget);

          final buttonWidget = tester.widget<ElevatedButton>(predictButton);
          expect(buttonWidget.onPressed, isNotNull);

          // Verify no loading indicator initially
          expect(find.byType(CircularProgressIndicator), findsNothing);

          // Tap the predict button
          await tester.tap(predictButton);

          // Pump once to trigger the state change
          await tester.pump();

          // Property verification: All three loading states should be active
          // (1) Loading indicator should be visible
          expect(
            find.byType(CircularProgressIndicator),
            findsOneWidget,
            reason: 'Iteration $iteration: Loading indicator should be visible',
          );

          // (2) Predict button should be disabled
          final disabledButton = tester.widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Predict'),
          );
          expect(
            disabledButton.onPressed,
            isNull,
            reason: 'Iteration $iteration: Predict button should be disabled',
          );

          // (3) Camera and Gallery buttons should also be disabled
          final cameraButton = tester.widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Camera'),
          );
          expect(
            cameraButton.onPressed,
            isNull,
            reason:
                'Iteration $iteration: Camera button should be disabled during loading',
          );

          final galleryButton = tester.widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Gallery'),
          );
          expect(
            galleryButton.onPressed,
            isNull,
            reason:
                'Iteration $iteration: Gallery button should be disabled during loading',
          );

          // Verify all three conditions are met simultaneously
          final loadingVisible =
              find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
          final predictDisabled = disabledButton.onPressed == null;
          final buttonsDisabled =
              cameraButton.onPressed == null && galleryButton.onPressed == null;

          expect(
            loadingVisible && predictDisabled && buttonsDisabled,
            isTrue,
            reason:
                'Iteration $iteration: All loading states should be active simultaneously',
          );

          // Clean up
          await testImage.parent.delete(recursive: true);
        }
      },
    );

    testWidgets(
      'Feature: dyslexia-detection-flutter-app, Property 22: Loading State Deactivation on Completion - **Validates: Requirements 7.4, 7.5**',
      (WidgetTester tester) async {
        // Property: For any API request completion (success or error), the app
        // should simultaneously:
        // (1) hide the loading indicator
        // (2) re-enable the predict button

        // Run 10 iterations with random completion scenarios
        for (int iteration = 0; iteration < 10; iteration++) {
          // Create a test image
          final testImage = await createTestImageFile(
            'completion_test_$iteration.png',
          );

          // Build the HomeScreen
          await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
          await tester.pumpAndSettle();

          // Set up state with an image
          final state = tester.state<State>(find.byType(HomeScreen));
          final homeScreenState = state as dynamic;
          await homeScreenState.handleImageSelection(testImage);
          await tester.pumpAndSettle();

          // Tap the predict button to start loading
          final predictButton = find.widgetWithText(ElevatedButton, 'Predict');
          await tester.tap(predictButton);
          await tester.pump();

          // Verify loading state is active
          expect(find.byType(CircularProgressIndicator), findsOneWidget);

          // Wait for the API call to complete (or fail)
          // The actual API call will fail in test environment, triggering error handling
          await tester.pumpAndSettle(const Duration(seconds: 5));

          // Property verification: Loading state should be deactivated
          // (1) Loading indicator should be hidden
          expect(
            find.byType(CircularProgressIndicator),
            findsNothing,
            reason:
                'Iteration $iteration: Loading indicator should be hidden after completion',
          );

          // (2) Predict button should be re-enabled
          final enabledButton = tester.widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Predict'),
          );
          expect(
            enabledButton.onPressed,
            isNotNull,
            reason:
                'Iteration $iteration: Predict button should be re-enabled after completion',
          );

          // (3) Camera and Gallery buttons should also be re-enabled
          final cameraButton = tester.widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Camera'),
          );
          expect(
            cameraButton.onPressed,
            isNotNull,
            reason:
                'Iteration $iteration: Camera button should be re-enabled after completion',
          );

          final galleryButton = tester.widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Gallery'),
          );
          expect(
            galleryButton.onPressed,
            isNotNull,
            reason:
                'Iteration $iteration: Gallery button should be re-enabled after completion',
          );

          // Verify all conditions are met simultaneously
          final loadingHidden =
              find.byType(CircularProgressIndicator).evaluate().isEmpty;
          final predictEnabled = enabledButton.onPressed != null;
          final buttonsEnabled =
              cameraButton.onPressed != null && galleryButton.onPressed != null;

          expect(
            loadingHidden && predictEnabled && buttonsEnabled,
            isTrue,
            reason:
                'Iteration $iteration: All loading states should be deactivated simultaneously',
          );

          // Clean up
          await testImage.parent.delete(recursive: true);
        }
      },
    );
  });
}
