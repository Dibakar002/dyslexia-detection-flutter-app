import 'package:flutter/material.dart';

/// Modal dialog that displays image capture guidelines to users before they
/// capture or select images for dyslexia detection.
///
/// This modal ensures users understand the requirements for quality handwriting
/// samples: white paper only, no objects in frame, good lighting, dark handwriting,
/// and entire text visible.
///
/// The modal is non-dismissible and requires the user to tap "I Understand"
/// before proceeding to the camera or gallery picker.
class InstructionModal extends StatelessWidget {
  /// Callback function invoked when the user taps "I Understand"
  final VoidCallback onUnderstood;

  const InstructionModal({super.key, required this.onUnderstood});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Prevent dismissal by back button
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.blue[50]!.withValues(alpha: 0.3)],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with icon
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Image Capture Guidelines',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Instruction list with checkmarks
                _buildInstructionItem(context, 'Only white paper visible'),
                const SizedBox(height: 14),
                _buildInstructionItem(context, 'No pen or objects in frame'),
                const SizedBox(height: 14),
                _buildInstructionItem(context, 'Good lighting (no shadows)'),
                const SizedBox(height: 14),
                _buildInstructionItem(
                  context,
                  'Dark handwriting (black/blue pen)',
                ),
                const SizedBox(height: 14),
                _buildInstructionItem(context, 'Entire text visible in frame'),
                const SizedBox(height: 28),

                // Visual examples section
                _buildVisualExamplesSection(context),
                const SizedBox(height: 28),

                // "I Understand" button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onUnderstood,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: const Text(
                      'I Understand',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a single instruction item with a checkmark icon
  Widget _buildInstructionItem(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle, color: Colors.green[700], size: 24),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
          ),
        ),
      ],
    );
  }

  /// Builds the visual examples section with placeholders for good vs bad images
  Widget _buildVisualExamplesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visual Examples',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildExamplePlaceholder(
                context,
                'Good Example',
                Colors.green[100]!,
                Icons.check_circle_outline,
                Colors.green[700]!,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildExamplePlaceholder(
                context,
                'Bad Example',
                Colors.red[100]!,
                Icons.cancel_outlined,
                Colors.red[700]!,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds a placeholder for visual example images
  Widget _buildExamplePlaceholder(
    BuildContext context,
    String label,
    Color backgroundColor,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 36),
          const SizedBox(height: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Static method to show the instruction modal
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false, // Non-dismissible without button tap
      builder:
          (context) =>
              InstructionModal(onUnderstood: () => Navigator.of(context).pop()),
    );
  }
}
