import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dyslexia_detection_app/main.dart';

/// Widget tests for theme styling, color scheme, spacing, and padding
///
/// Validates: Requirements 11.1, 11.2, 11.3, 11.4, 11.5, 11.6
void main() {
  group('Theme Styling Tests', () {
    testWidgets('App uses professional academic healthcare color scheme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const DyslexiaDetectionApp());
      await tester.pumpAndSettle();

      // Get the MaterialApp widget
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final theme = materialApp.theme!;

      // Verify primary color is a professional blue
      expect(
        theme.colorScheme.primary,
        equals(const Color(0xFF2C5F8D)),
        reason: 'Primary color should be deep professional blue',
      );

      // Verify secondary color
      expect(
        theme.colorScheme.secondary,
        equals(const Color(0xFF4A90A4)),
        reason: 'Secondary color should be lighter teal blue',
      );

      // Verify tertiary/accent color
      expect(
        theme.colorScheme.tertiary,
        equals(const Color(0xFF7FB3D5)),
        reason: 'Tertiary color should be soft accent blue',
      );

      // Verify background color
      expect(
        theme.scaffoldBackgroundColor,
        equals(const Color(0xFFF5F7FA)),
        reason: 'Background should be clean light color',
      );

      // Verify surface color
      expect(
        theme.colorScheme.surface,
        equals(Colors.white),
        reason: 'Surface color should be white',
      );
    });

    testWidgets('AppBar theme uses professional styling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const DyslexiaDetectionApp());
      await tester.pumpAndSettle();

      // Get the MaterialApp widget
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final theme = materialApp.theme!;
      final appBarTheme = theme.appBarTheme;

      // Verify AppBar theme background color
      expect(
        appBarTheme.backgroundColor,
        equals(const Color(0xFF2C5F8D)),
        reason: 'AppBar should use primary color',
      );

      // Verify AppBar foreground color
      expect(
        appBarTheme.foregroundColor,
        equals(Colors.white),
        reason: 'AppBar text should be white',
      );

      // Verify AppBar is centered
      expect(
        appBarTheme.centerTitle,
        isTrue,
        reason: 'AppBar title should be centered',
      );

      // Verify AppBar has elevation
      expect(
        appBarTheme.elevation,
        equals(2),
        reason: 'AppBar should have subtle elevation',
      );
    });

    testWidgets('Card theme has elevation and rounded corners', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const DyslexiaDetectionApp());
      await tester.pumpAndSettle();

      // Get the MaterialApp widget
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final theme = materialApp.theme!;
      final cardTheme = theme.cardTheme;

      // Verify card has elevation
      expect(
        cardTheme.elevation,
        equals(4),
        reason: 'Cards should have elevation of 4',
      );

      // Verify card has rounded corners
      expect(cardTheme.shape, isA<RoundedRectangleBorder>());
      if (cardTheme.shape is RoundedRectangleBorder) {
        final shape = cardTheme.shape as RoundedRectangleBorder;
        final borderRadius = shape.borderRadius as BorderRadius;
        expect(
          borderRadius.topLeft.x,
          equals(16),
          reason: 'Cards should have 16px border radius',
        );
      }

      // Verify card color is white
      expect(
        cardTheme.color,
        equals(Colors.white),
        reason: 'Cards should have white background',
      );
    });

    testWidgets('Text theme uses consistent styling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const DyslexiaDetectionApp());
      await tester.pumpAndSettle();

      // Get the MaterialApp widget
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final theme = materialApp.theme!;
      final textTheme = theme.textTheme;

      // Verify headline styles
      expect(textTheme.headlineLarge?.fontSize, equals(32));
      expect(textTheme.headlineLarge?.fontWeight, equals(FontWeight.bold));
      expect(textTheme.headlineMedium?.fontSize, equals(24));
      expect(textTheme.headlineMedium?.fontWeight, equals(FontWeight.bold));

      // Verify title styles
      expect(textTheme.titleLarge?.fontSize, equals(20));
      expect(textTheme.titleLarge?.fontWeight, equals(FontWeight.w600));
      expect(textTheme.titleMedium?.fontSize, equals(16));
      expect(textTheme.titleMedium?.fontWeight, equals(FontWeight.w500));

      // Verify body styles
      expect(textTheme.bodyLarge?.fontSize, equals(16));
      expect(textTheme.bodyMedium?.fontSize, equals(14));

      // Verify letter spacing for professional look
      expect(textTheme.headlineLarge?.letterSpacing, equals(0.5));
      expect(textTheme.titleLarge?.letterSpacing, equals(0.5));
    });

    testWidgets('SnackBar has rounded corners', (WidgetTester tester) async {
      await tester.pumpWidget(const DyslexiaDetectionApp());
      await tester.pumpAndSettle();

      // Get the MaterialApp widget
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final theme = materialApp.theme!;
      final snackBarTheme = theme.snackBarTheme;

      // Verify SnackBar behavior is floating
      expect(snackBarTheme.behavior, equals(SnackBarBehavior.floating));

      // Verify SnackBar has rounded corners
      expect(snackBarTheme.shape, isA<RoundedRectangleBorder>());
      if (snackBarTheme.shape is RoundedRectangleBorder) {
        final shape = snackBarTheme.shape as RoundedRectangleBorder;
        final borderRadius = shape.borderRadius as BorderRadius;
        expect(
          borderRadius.topLeft.x,
          equals(12),
          reason: 'SnackBar should have 12px border radius',
        );
      }
    });

    testWidgets('Visual consistency across all components', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const DyslexiaDetectionApp());
      await tester.pumpAndSettle();

      // Get the MaterialApp widget
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final theme = materialApp.theme!;

      // Verify Material 3 is enabled for modern design
      expect(
        theme.useMaterial3,
        isTrue,
        reason: 'Should use Material 3 for modern design',
      );

      // Verify consistent color scheme across components
      expect(theme.colorScheme.primary, isNotNull);
      expect(theme.colorScheme.secondary, isNotNull);
      expect(theme.colorScheme.tertiary, isNotNull);
      expect(theme.colorScheme.surface, isNotNull);
      expect(theme.colorScheme.error, isNotNull);

      // Verify all on-colors are defined for proper contrast
      expect(theme.colorScheme.onPrimary, equals(Colors.white));
      expect(theme.colorScheme.onSecondary, equals(Colors.white));
      expect(theme.colorScheme.onSurface, isNotNull);
      expect(theme.colorScheme.onError, equals(Colors.white));
    });

    testWidgets('Proper spacing and padding values are defined', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const DyslexiaDetectionApp());
      await tester.pumpAndSettle();

      // Get the MaterialApp widget
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final theme = materialApp.theme!;

      // Verify button padding
      final buttonPadding = theme.elevatedButtonTheme.style?.padding?.resolve(
        {},
      );
      expect(
        buttonPadding,
        isNotNull,
        reason: 'Button padding should be defined',
      );

      // Verify card margin
      final cardMargin = theme.cardTheme.margin;
      expect(cardMargin, isNotNull, reason: 'Card margin should be defined');
    });
  });
}
