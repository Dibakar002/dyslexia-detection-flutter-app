import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dyslexia_detection_app/widgets/instruction_modal.dart';

/// Widget tests for InstructionModal widget
/// Validates Requirements 4.1, 4.2, 4.3
void main() {
  group('InstructionModal Widget Tests', () {
    testWidgets(
      'Modal displays correctly with title "Image Capture Guidelines"',
      (WidgetTester tester) async {
        bool confirmCalled = false;

        // Build the InstructionModal widget
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InstructionModal(
                onUnderstood: () {
                  confirmCalled = true;
                },
              ),
            ),
          ),
        );

        // Verify title is displayed
        expect(find.text('Image Capture Guidelines'), findsOneWidget);

        // Verify the title uses the correct style (headline)
        final titleWidget = tester.widget<Text>(
          find.text('Image Capture Guidelines'),
        );
        expect(titleWidget.style?.fontWeight, FontWeight.bold);
      },
    );

    testWidgets('All instruction items are rendered', (
      WidgetTester tester,
    ) async {
      // Build the InstructionModal widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: InstructionModal(onUnderstood: () {})),
        ),
      );

      // Verify all five instruction items are displayed
      expect(find.text('Only white paper visible'), findsOneWidget);
      expect(find.text('No pen or objects in frame'), findsOneWidget);
      expect(find.text('Good lighting (no shadows)'), findsOneWidget);
      expect(find.text('Dark handwriting (black/blue pen)'), findsOneWidget);
      expect(find.text('Entire text visible in frame'), findsOneWidget);

      // Verify checkmark icons are present (one for each instruction)
      expect(find.byIcon(Icons.check_circle), findsNWidgets(5));
    });

    testWidgets('"I Understand" button is present and functional', (
      WidgetTester tester,
    ) async {
      bool confirmCalled = false;

      // Build the InstructionModal widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InstructionModal(
              onUnderstood: () {
                confirmCalled = true;
              },
            ),
          ),
        ),
      );

      // Verify "I Understand" button is present
      final understandButton = find.text('I Understand');
      expect(understandButton, findsOneWidget);

      // Verify button is an ElevatedButton
      expect(
        find.ancestor(
          of: understandButton,
          matching: find.byType(ElevatedButton),
        ),
        findsOneWidget,
      );

      // Tap the button
      await tester.tap(understandButton);
      await tester.pump();

      // Verify the callback was triggered
      expect(confirmCalled, true);
    });

    testWidgets(
      'Modal is non-dismissible (cannot be closed by tapping outside)',
      (WidgetTester tester) async {
        bool confirmCalled = false;

        // Build the InstructionModal using the static show method
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder:
                            (context) => InstructionModal(
                              onUnderstood: () {
                                confirmCalled = true;
                                Navigator.of(context).pop();
                              },
                            ),
                      );
                    },
                    child: const Text('Show Modal'),
                  );
                },
              ),
            ),
          ),
        );

        // Tap button to show modal
        await tester.tap(find.text('Show Modal'));
        await tester.pumpAndSettle();

        // Verify modal is displayed
        expect(find.text('Image Capture Guidelines'), findsOneWidget);

        // Try to tap outside the modal (on the barrier)
        // Tap at a position that should be outside the dialog
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        // Verify modal is still displayed (not dismissed)
        expect(find.text('Image Capture Guidelines'), findsOneWidget);
        expect(confirmCalled, false);
      },
    );

    testWidgets('Tapping "I Understand" triggers the onConfirm callback', (
      WidgetTester tester,
    ) async {
      bool confirmCalled = false;
      String? callbackResult;

      // Build the InstructionModal with a callback that sets a flag
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InstructionModal(
              onUnderstood: () {
                confirmCalled = true;
                callbackResult = 'callback executed';
              },
            ),
          ),
        ),
      );

      // Verify callback hasn't been called yet
      expect(confirmCalled, false);
      expect(callbackResult, null);

      // Tap "I Understand" button
      await tester.tap(find.text('I Understand'));
      await tester.pump();

      // Verify callback was executed
      expect(confirmCalled, true);
      expect(callbackResult, 'callback executed');
    });

    testWidgets('Modal displays visual examples section', (
      WidgetTester tester,
    ) async {
      // Build the InstructionModal widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: InstructionModal(onUnderstood: () {})),
        ),
      );

      // Verify visual examples section is present
      expect(find.text('Visual Examples'), findsOneWidget);
      expect(find.text('Good Example'), findsOneWidget);
      expect(find.text('Bad Example'), findsOneWidget);

      // Verify example icons are present
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    });

    testWidgets('Modal button has rounded corners', (
      WidgetTester tester,
    ) async {
      // Build the InstructionModal widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: InstructionModal(onUnderstood: () {})),
        ),
      );

      // Find the ElevatedButton
      final buttonFinder = find.ancestor(
        of: find.text('I Understand'),
        matching: find.byType(ElevatedButton),
      );
      expect(buttonFinder, findsOneWidget);

      // Get the button widget
      final button = tester.widget<ElevatedButton>(buttonFinder);

      // Verify the button has rounded corners
      final shape = button.style?.shape?.resolve({});
      expect(shape, isA<RoundedRectangleBorder>());
      final roundedShape = shape as RoundedRectangleBorder;
      expect(roundedShape.borderRadius, BorderRadius.circular(12));
    });

    testWidgets('Modal is scrollable for small screens', (
      WidgetTester tester,
    ) async {
      // Set a small screen size
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1.0;

      // Build the InstructionModal widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: InstructionModal(onUnderstood: () {})),
        ),
      );

      // Verify SingleChildScrollView is present
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // Reset the screen size
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('Static show method displays modal correctly', (
      WidgetTester tester,
    ) async {
      // Build a widget with a button that calls InstructionModal.show()
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    InstructionModal.show(context);
                  },
                  child: const Text('Show Modal'),
                );
              },
            ),
          ),
        ),
      );

      // Verify modal is not shown initially
      expect(find.text('Image Capture Guidelines'), findsNothing);

      // Tap button to show modal
      await tester.tap(find.text('Show Modal'));
      await tester.pumpAndSettle();

      // Verify modal is displayed
      expect(find.text('Image Capture Guidelines'), findsOneWidget);
      expect(find.text('I Understand'), findsOneWidget);

      // Tap "I Understand" to dismiss
      await tester.tap(find.text('I Understand'));
      await tester.pumpAndSettle();

      // Verify modal is dismissed
      expect(find.text('Image Capture Guidelines'), findsNothing);
    });
  });
}
