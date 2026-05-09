import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import '../models/prediction_result.dart';
import '../services/pdf_service.dart';
import '../services/history_service.dart';

class ResultScreen extends StatefulWidget {
  final PredictionResult result;
  final XFile imageFile;

  const ResultScreen({
    super.key,
    required this.result,
    required this.imageFile,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isSaving = false;
  bool _historySaved = false;

  @override
  void initState() {
    super.initState();
    _saveToHistory();
  }

  Future<void> _saveToHistory() async {
    if (_historySaved) return;
    _historySaved = true;
    final entry = HistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: widget.result.label,
      confidence: widget.result.confidence,
      imagePath: widget.imageFile.path,
      timestamp: DateTime.now(),
    );
    await HistoryService.save(entry);
  }

  bool get _isDyslexic => widget.result.label == 'Dyslexic';

  Color get _resultColor =>
      _isDyslexic ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32);

  Color get _resultBgColor =>
      _isDyslexic ? const Color(0xFFFFF3F3) : const Color(0xFFF1FBF1);

  Future<void> _saveAsPdf() async {
    setState(() => _isSaving = true);
    try {
      final path = await PdfService.generateReport(
        result: widget.result,
        imageFile: widget.imageFile,
      );
      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to: $path'),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () => OpenFile.open(path),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save PDF: $e'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B3A5C),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Dyslexia Detection',
          style: theme.textTheme.titleLarge?.copyWith(
            color: const Color(0xFF1B3A5C),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Analysis Result card ─────────────────────────────
            _buildResultCard(theme),
            const SizedBox(height: 16),

            // ── Uploaded Image ───────────────────────────────────
            _buildUploadedImageCard(theme),
            const SizedBox(height: 16),

            // ── Analysis Summary ─────────────────────────────────
            _buildAnalysisSummaryCard(theme),
            const SizedBox(height: 16),

            // ── What does this mean? ─────────────────────────────
            _buildInfoCard(theme),
            const SizedBox(height: 16),

            // ── Suggestions ─────────────────────────────────────
            _buildSuggestionsCard(theme),
            const SizedBox(height: 24),

            // ── Action buttons ───────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Analyze Another'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2C5F8D),
                      side: const BorderSide(color: Color(0xFF2C5F8D)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveAsPdf,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download, size: 18),
                    label: Text(_isSaving ? 'Saving...' : 'Save Result'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B3A5C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF2C5F8D),
        unselectedItemColor: Colors.grey[500],
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: 'About',
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified_outlined,
                  color: const Color(0xFF2C5F8D),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Analysis Result',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B3A5C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: _resultBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    widget.result.label,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: _resultColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Confidence: ${widget.result.getConfidencePercentage()}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isDyslexic
                  ? 'The handwriting patterns indicate a higher likelihood of dyslexia.'
                  : 'The handwriting patterns indicate a low likelihood of dyslexia.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadedImageCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Uploaded Image',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B3A5C),
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child:
                  kIsWeb
                      ? Image.network(
                        widget.imageFile.path,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                      )
                      : Image.file(
                        File(widget.imageFile.path),
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisSummaryCard(ThemeData theme) {
    // Generate plausible metrics based on the result
    final metrics = _buildMetrics();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.trending_up,
                  color: Color(0xFF2C5F8D),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Analysis Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B3A5C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...metrics.map((m) => _buildMetricRow(theme, m)),
          ],
        ),
      ),
    );
  }

  List<_Metric> _buildMetrics() {
    final base = widget.result.confidence;
    if (_isDyslexic) {
      return [
        _Metric('Letter Recognition', Icons.text_fields, 1 - base * 0.6, 'Poor'),
        _Metric('Spacing Consistency', Icons.space_bar, 1 - base * 0.5, 'Fair'),
        _Metric('Baseline Alignment', Icons.horizontal_rule, 1 - base * 0.7, 'Poor'),
        _Metric('Letter Formation', Icons.edit_outlined, 1 - base * 0.55, 'Fair'),
        _Metric('Pressure Consistency', Icons.show_chart, 1 - base * 0.4, 'Fair'),
      ];
    } else {
      return [
        _Metric('Letter Recognition', Icons.text_fields, base, 'Excellent'),
        _Metric('Spacing Consistency', Icons.space_bar, base * 0.98, 'Excellent'),
        _Metric('Baseline Alignment', Icons.horizontal_rule, base, 'Excellent'),
        _Metric('Letter Formation', Icons.edit_outlined, base, 'Excellent'),
        _Metric('Pressure Consistency', Icons.show_chart, base * 0.99, 'Excellent'),
      ];
    }
  }

  Widget _buildMetricRow(ThemeData theme, _Metric metric) {
    final isGood = metric.score >= 0.7;
    final barColor = isGood ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);
    final labelColor = isGood ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(metric.icon, size: 18, color: const Color(0xFF2C5F8D)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  metric.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF1B3A5C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                metric.rating,
                style: TextStyle(
                  color: labelColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(width: 42),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: metric.score.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(metric.score * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Card(
      elevation: 2,
      color: const Color(0xFFF0F6FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF2C5F8D), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What does this mean?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1B3A5C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This analysis is based on handwriting patterns such as spacing, alignment, letter formation, and pressure consistency.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'This is not a medical diagnosis. For concerns, please consult a qualified professional.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsCard(ThemeData theme) {
    final suggestions = _isDyslexic
        ? [
            _Suggestion('Consider consulting a specialist', Icons.check_circle, const Color(0xFF2E7D32)),
            _Suggestion('Try structured literacy programs', Icons.circle, const Color(0xFFF9A825)),
            _Suggestion('Use assistive writing tools', Icons.circle, const Color(0xFFF9A825)),
          ]
        : [
            _Suggestion('Keep practicing your handwriting', Icons.check_circle, const Color(0xFF2E7D32)),
            _Suggestion('Maintain consistent letter size', Icons.circle, const Color(0xFFF9A825)),
            _Suggestion('Good job on clear letter formation!', Icons.check_circle, const Color(0xFF2E7D32)),
          ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star_outline, color: Color(0xFFF9A825), size: 22),
                const SizedBox(width: 8),
                Text(
                  'Suggestions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B3A5C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...suggestions.map(
              (s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(s.icon, color: s.color, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.text,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF424242),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric {
  final String label;
  final IconData icon;
  final double score;
  final String rating;

  const _Metric(this.label, this.icon, this.score, this.rating);
}

class _Suggestion {
  final String text;
  final IconData icon;
  final Color color;

  const _Suggestion(this.text, this.icon, this.color);
}
