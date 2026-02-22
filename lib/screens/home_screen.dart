import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/prediction_result.dart';

/// Ultra-simple home screen for dyslexia detection
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  PredictionResult? _result;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dyslexia Detection'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview
            Expanded(
              child: Card(
                elevation: 3,
                child:
                    _selectedImage != null
                        ? (kIsWeb
                            ? Image.network(
                              _selectedImage!.path,
                              fit: BoxFit.contain,
                            )
                            : Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.contain,
                            ))
                        : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_outlined,
                                size: 72,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No image selected',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
              ),
            ),

            const SizedBox(height: 16),

            // Result display
            if (_result != null)
              Card(
                color: _result!.getResultColor().withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        _result!.label,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _result!.getResultColor(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Confidence: ${_result!.getConfidencePercentage()}',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Upload button
            ElevatedButton.icon(
              onPressed: _pickImageFromGallery,
              icon: const Icon(Icons.upload),
              label: const Text('Upload Image'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 12),

            // Predict button
            ElevatedButton.icon(
              onPressed:
                  _selectedImage == null || _isLoading
                      ? null
                      : _predictDyslexia,
              icon:
                  _isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.psychology),
              label: Text(_isLoading ? 'Predicting...' : 'Predict'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens gallery to select image
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _result = null; // Clear previous result
        });
      }
    } catch (e) {
      _showError('Failed to select image: $e');
    }
  }

  /// Sends raw image bytes to API for prediction
  Future<void> _predictDyslexia() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      // Read raw image bytes (works on both mobile and web)
      final imageBytes = await _selectedImage!.readAsBytes();

      // Send to API
      final result = await _apiService.predictDyslexia(imageBytes);

      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Prediction failed: $e');
    }
  }

  /// Shows error message
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red[700]),
      );
    }
  }
}
