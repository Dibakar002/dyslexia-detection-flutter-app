import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/prediction_result.dart';

/// Service class for handling HTTP communication with the dyslexia detection backend API.
///
/// This service manages:
/// - Multipart/form-data POST requests to the prediction endpoint
/// - Cold start detection for serverless deployments
/// - Comprehensive error classification and handling
/// - JSON response parsing
class ApiService {
  /// Base URL for the FastAPI backend hosted on Hugging Face Spaces
  static const String baseUrl = 'https://dibakarb-dyslexia-backend.hf.space';

  /// Maximum time to wait for API response (60 seconds to accommodate cold starts)
  static const Duration timeout = Duration(seconds: 60);

  /// Threshold for detecting cold start (5 seconds)
  static const Duration coldStartThreshold = Duration(seconds: 5);

  /// HTTP client for making requests (injectable for testing)
  final http.Client client;

  /// Creates an ApiService with an optional HTTP client.
  /// If no client is provided, a default client is used.
  ApiService({http.Client? client}) : client = client ?? http.Client();

  /// Sends a preprocessed handwriting image to the backend API for dyslexia prediction.
  ///
  /// Parameters:
  /// - [imageBytes]: The preprocessed image as a byte array (should be 64x256 grayscale)
  /// - [onColdStart]: Optional callback triggered after 5 seconds if no response received
  ///
  /// Returns a [PredictionResult] containing the prediction label and confidence score.
  ///
  /// Throws:
  /// - [NetworkException] if no internet connection is available
  /// - [TimeoutException] if the request exceeds 60 seconds
  /// - [ServerException] if the server returns a 5xx error
  /// - [ClientException] if the request is invalid (4xx error)
  /// - [InvalidResponseException] if the response cannot be parsed
  Future<PredictionResult> predictDyslexia(
    Uint8List imageBytes, {
    Function? onColdStart,
  }) async {
    Timer? coldStartTimer;
    bool requestCompleted = false;

    try {
      // Start cold start detection timer
      if (onColdStart != null) {
        coldStartTimer = Timer(coldStartThreshold, () {
          if (!requestCompleted) {
            onColdStart();
          }
        });
      }

      // Create multipart request
      final uri = Uri.parse('$baseUrl/predict/');
      final request = http.MultipartRequest('POST', uri);

      // Add image as multipart file field
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'handwriting.jpg',
        ),
      );

      // Send request with timeout using the injected client
      final streamedResponse = await client
          .send(request)
          .timeout(
            timeout,
            onTimeout: () {
              throw TimeoutException(
                'Request timed out after ${timeout.inSeconds} seconds',
              );
            },
          );

      // Mark request as completed to prevent cold start callback
      requestCompleted = true;
      coldStartTimer?.cancel();

      // Get response body
      final response = await http.Response.fromStream(streamedResponse);

      // Handle HTTP status codes
      if (response.statusCode >= 500) {
        throw ServerException(
          'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode >= 400) {
        throw ClientException(
          'Client error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode != 200) {
        throw InvalidResponseException(
          'Unexpected status code: ${response.statusCode}',
        );
      }

      // Parse JSON response
      try {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        return PredictionResult.fromJson(jsonResponse);
      } catch (e) {
        throw InvalidResponseException('Failed to parse response: $e');
      }
    } on SocketException catch (e) {
      requestCompleted = true;
      coldStartTimer?.cancel();
      throw NetworkException('No internet connection: ${e.message}');
    } on TimeoutException catch (e) {
      requestCompleted = true;
      coldStartTimer?.cancel();
      throw TimeoutException(e.message ?? 'Request timed out');
    } catch (e) {
      requestCompleted = true;
      coldStartTimer?.cancel();
      rethrow;
    }
  }
}

/// Exception thrown when network connectivity is unavailable
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception thrown when the server returns a 5xx error
class ServerException implements Exception {
  final String message;
  final int statusCode;

  ServerException(this.message, {required this.statusCode});

  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}

/// Exception thrown when the client request is invalid (4xx error)
class ClientException implements Exception {
  final String message;
  final int statusCode;

  ClientException(this.message, {required this.statusCode});

  @override
  String toString() => 'ClientException: $message (Status: $statusCode)';
}

/// Exception thrown when the API response cannot be parsed
class InvalidResponseException implements Exception {
  final String message;

  InvalidResponseException(this.message);

  @override
  String toString() => 'InvalidResponseException: $message';
}
