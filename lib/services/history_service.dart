import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A single history entry stored locally on the device.
class HistoryEntry {
  final String id;
  final String label;         // "Dyslexic" | "Non-Dyslexic"
  final double confidence;
  final String imagePath;     // absolute path to the image file
  final DateTime timestamp;

  HistoryEntry({
    required this.id,
    required this.label,
    required this.confidence,
    required this.imagePath,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'confidence': confidence,
        'imagePath': imagePath,
        'timestamp': timestamp.toIso8601String(),
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        id: json['id'] as String,
        label: json['label'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        imagePath: json['imagePath'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  String getConfidencePercentage() =>
      '${(confidence * 100).toStringAsFixed(1)}%';
}

/// Manages reading/writing history entries via SharedPreferences.
class HistoryService {
  static const _key = 'dyslexia_history';

  /// Returns all entries, newest first.
  static Future<List<HistoryEntry>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => HistoryEntry.fromJson(jsonDecode(s)))
        .toList()
        .reversed
        .toList();
  }

  /// Saves a new entry (appended to the list).
  static Future<void> save(HistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(jsonEncode(entry.toJson()));
    await prefs.setStringList(_key, raw);
  }

  /// Deletes a single entry by id.
  static Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.removeWhere((s) {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return m['id'] == id;
    });
    await prefs.setStringList(_key, raw);
  }

  /// Clears all history.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
