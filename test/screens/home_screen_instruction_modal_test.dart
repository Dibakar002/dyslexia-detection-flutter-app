import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dyslexia_detection_app/screens/home_screen.dart';

/// Widget tests for instruction modal flow in HomeScreen
/// Validates Requirements 4.1, 4.2, 4.3, 4.5
void main() {
  group('HomeScreen Instruction Modal Flow', () {
    testWidgets('Camera button shows instruction modal on first tap', (
      WidgetTester tester,
    ) async {
      // Build the HomeScreen
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Verify modal is not shown initially
      expect(find.text('Image Capture Guidelines'), findsNothing);

      // Tap the camera button
      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();

      // Verify instruction modal is displayed
      expect(find.text('Image Capture Guidelines'), findsOneWidget);
      expect(find.text('Only white paper visible'), findsOneWidget);
      expect(find.text('No pen or objects in frame'), findsOneWidget);
      expect(find.text('Good lighting (no shadows)'), findsOneWidget);
      expect(find.text('Dark handwriting (black/blue pen)'), findsOneWidget);
      expect(find.text('Entire text visible in frame'), findsOneWidget);
      expect(find.text('I Understand'), findsOneWidget);
    });

    testWidgets('Gallery button shows instruction modal on first tap', (
      WidgetTester tester,
    ) async {
      // Build the HomeScreen
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Verify modal is not shown initially
      expect(find.text('Image Capture Guidelines'), findsNothing);

      // Tap the gallery button
      await tester.tap(find.text('Gallery'));
      await tester.pumpAndSettle();

      // Verify instruction modal is displayed
      expect(find.text('Image Capture Guidelines'), findsOneWidget);
      expect(find.text('I Understand'), findsOneWidget);
    });

    testWidgets('Instruction modal only shows once per session', (
      WidgetTester tester,
    ) async {
      // Build the HomeScreen
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // First tap on camera button
      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();

      // Verify modal is shown
      expect(find.text('Image Capture Guidelines'), findsOneWidget);

      // Tap "I Understand" to dismiss modal
      await tester.tap(find.text('I Understand'));
      await tester.pumpAndSettle();

      // Verify modal is dismissed
      expect(find.text('Image Capture Guidelines'), findsNothing);

      // Second tap on gallery button
      await tester.tap(find.text('Gallery'));
      await tester.pumpAndSettle();

      // Verify modal is NOT shown again (hasSeenInstructions = true)
      expect(find.text('Image Capture Guidelines'), findsNothing);
    });

    testWidgets('User must tap "I Understand" to proceed', (
      WidgetTester tester,
    ) async {
      // Build the HomeScreen
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Tap the camera button
      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();

      // Verify modal is displayed
      expect(find.text('Image Capture Guidelines'), findsOneWidget);

      // Verify "I Understand" button is present and tappable
      final understandButton = find.text('I Understand');
      expect(understandButton, findsOneWidget);

      // Tap "I Understand"
      await tester.tap(understandButton);
      await tester.pumpAndSettle();

      // Verify modal is dismissed
      expect(find.text('Image Capture Guidelines'), findsNothing);
    });

    testWidgets('Modal cannot be dismissed without tapping "I Understand"', (
      WidgetTester tester,
    ) async {
      // Build the HomeScreen
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Tap the camera button
      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();

      // Verify modal is displayed
      expect(find.text('Image Capture Guidelines'), findsOneWidget);

      // Try to tap outside the modal (on the barrier)
      // The modal should remain visible because barrierDismissible is false
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Verify modal is still displayed
      expect(find.text('Image Capture Guidelines'), findsOneWidget);
    });
  });
}
