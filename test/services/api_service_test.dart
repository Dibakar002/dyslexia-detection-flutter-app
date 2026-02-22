import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:dyslexia_detection_app/services/api_service.dart';
import 'package:dyslexia_detection_app/models/prediction_result.dart';

import 'api_service_test.mocks.dart';

// Generate mocks for http.Client
@GenerateMocks([http.Client])
void main() {
  group('ApiService Unit Tests', () {
    late MockClient mockClient;
    late ApiService apiService;

    setUp(() {
      mockClient = MockClient();
      apiService = ApiService(client: mockClient);
    });

    group('Constants', () {
      test('baseUrl should be correct', () {
        expect(
          ApiService.baseUrl,
          equals('https://dibakarb-dyslexia-backend.hf.space'),
        );
      });

      test('timeout should be 60 seconds', () {
        expect(ApiService.timeout, equals(const Duration(seconds: 60)));
      });

      test('coldStartThreshold should be 5 seconds', () {
        expect(
          ApiService.coldStartThreshold,
          equals(const Duration(seconds: 5)),
        );
      });
    });

    group('API Request Construction', () {
      test(
        'should construct multipart request with correct endpoint',
        () async {
          // Arrange
          final imageBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
          final responseBody = json.encode({
            'prediction': 0,
            'label': 'Non-Dyslexic',
            'confidence': 0.95,
          });

          // Mock the HTTP client to return a successful response
          when(mockClient.send(any)).thenAnswer((_) async {
            return http.StreamedResponse(
              Stream.value(utf8.encode(responseBody)),
              200,
              headers: {'content-type': 'application/json'},
            );
          });

          // Act
          await apiService.predictDyslexia(imageBytes);

          // Assert - verify the request was sent
          final captured = verify(mockClient.send(captureAny)).captured;
          expect(captured.length, equals(1));

          final request = captured[0] as http.MultipartRequest;
          expect(request.method, equals('POST'));
          expect(
            request.url.toString(),
            equals('https://dibakarb-dyslexia-backend.hf.space/predict/'),
          );
        },
      );

      test(
        'should use "file" field name for image in multipart request',
        () async {
          // Arrange
          final imageBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
          final responseBody = json.encode({
            'prediction': 0,
            'label': 'Non-Dyslexic',
            'confidence': 0.95,
          });

          when(mockClient.send(any)).thenAnswer((_) async {
            return http.StreamedResponse(
              Stream.value(utf8.encode(responseBody)),
              200,
            );
          });

          // Act
          await apiService.predictDyslexia(imageBytes);

          // Assert
          final captured = verify(mockClient.send(captureAny)).captured;
          final request = captured[0] as http.MultipartRequest;

          expect(request.files.length, equals(1));
          expect(request.files[0].field, equals('file'));
          expect(request.files[0].filename, equals('handwriting.jpg'));
        },
      );

      test('should include image bytes in multipart request', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([10, 20, 30, 40, 50]);
        final responseBody = json.encode({
          'prediction': 1,
          'label': 'Dyslexic',
          'confidence': 0.87,
        });

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(responseBody)),
            200,
          );
        });

        // Act
        await apiService.predictDyslexia(imageBytes);

        // Assert
        final captured = verify(mockClient.send(captureAny)).captured;
        final request = captured[0] as http.MultipartRequest;

        expect(request.files[0].length, equals(5));
      });
    });

    group('JSON Response Parsing', () {
      test('should parse valid Non-Dyslexic response correctly', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        final responseBody = json.encode({
          'prediction': 0,
          'label': 'Non-Dyslexic',
          'confidence': 0.95,
        });

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(responseBody)),
            200,
          );
        });

        // Act
        final result = await apiService.predictDyslexia(imageBytes);

        // Assert
        expect(result.prediction, equals(0));
        expect(result.label, equals('Non-Dyslexic'));
        expect(result.confidence, equals(0.95));
      });

      test('should parse valid Dyslexic response correctly', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        final responseBody = json.encode({
          'prediction': 1,
          'label': 'Dyslexic',
          'confidence': 0.87,
        });

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(responseBody)),
            200,
          );
        });

        // Act
        final result = await apiService.predictDyslexia(imageBytes);

        // Assert
        expect(result.prediction, equals(1));
        expect(result.label, equals('Dyslexic'));
        expect(result.confidence, equals(0.87));
      });

      test('should handle confidence as integer', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        final responseBody = json.encode({
          'prediction': 0,
          'label': 'Non-Dyslexic',
          'confidence': 1,
        });

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(responseBody)),
            200,
          );
        });

        // Act
        final result = await apiService.predictDyslexia(imageBytes);

        // Assert
        expect(result.confidence, equals(1.0));
      });

      test('should parse various confidence values correctly', () async {
        final testCases = [
          {'prediction': 0, 'label': 'Non-Dyslexic', 'confidence': 0.0},
          {'prediction': 0, 'label': 'Non-Dyslexic', 'confidence': 0.5},
          {'prediction': 1, 'label': 'Dyslexic', 'confidence': 0.99},
          {'prediction': 1, 'label': 'Dyslexic', 'confidence': 1.0},
        ];

        for (final testCase in testCases) {
          // Arrange
          final imageBytes = Uint8List.fromList([1, 2, 3]);
          final responseBody = json.encode(testCase);

          when(mockClient.send(any)).thenAnswer((_) async {
            return http.StreamedResponse(
              Stream.value(utf8.encode(responseBody)),
              200,
            );
          });

          // Act
          final result = await apiService.predictDyslexia(imageBytes);

          // Assert
          expect(result.confidence, equals(testCase['confidence']));
        }
      });

      test(
        'should throw InvalidResponseException for malformed JSON',
        () async {
          // Arrange
          final imageBytes = Uint8List.fromList([1, 2, 3]);
          final responseBody = 'invalid json {{{';

          when(mockClient.send(any)).thenAnswer((_) async {
            return http.StreamedResponse(
              Stream.value(utf8.encode(responseBody)),
              200,
            );
          });

          // Act & Assert
          expect(
            () => apiService.predictDyslexia(imageBytes),
            throwsA(isA<InvalidResponseException>()),
          );
        },
      );

      test(
        'should throw InvalidResponseException for missing fields',
        () async {
          // Arrange
          final imageBytes = Uint8List.fromList([1, 2, 3]);
          final responseBody = json.encode({
            'prediction': 0,
            // Missing 'label' and 'confidence'
          });

          when(mockClient.send(any)).thenAnswer((_) async {
            return http.StreamedResponse(
              Stream.value(utf8.encode(responseBody)),
              200,
            );
          });

          // Act & Assert
          expect(
            () => apiService.predictDyslexia(imageBytes),
            throwsA(isA<InvalidResponseException>()),
          );
        },
      );
    });

    group('Cold Start Callback', () {
      test('should trigger callback after 5 seconds if no response', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        bool coldStartCalled = false;
        final completer = Completer<void>();

        // Mock a delayed response (6 seconds)
        when(mockClient.send(any)).thenAnswer((_) async {
          await Future.delayed(const Duration(seconds: 6));
          final responseBody = json.encode({
            'prediction': 0,
            'label': 'Non-Dyslexic',
            'confidence': 0.95,
          });
          return http.StreamedResponse(
            Stream.value(utf8.encode(responseBody)),
            200,
          );
        });

        // Act
        final future = apiService.predictDyslexia(
          imageBytes,
          onColdStart: () {
            coldStartCalled = true;
            completer.complete();
          },
        );

        // Wait for cold start callback
        await completer.future.timeout(
          const Duration(seconds: 7),
          onTimeout: () {},
        );

        // Assert
        expect(coldStartCalled, isTrue);

        // Clean up - wait for the request to complete
        await future;
      });

      test(
        'should not trigger callback if response arrives within 5 seconds',
        () async {
          // Arrange
          final imageBytes = Uint8List.fromList([1, 2, 3]);
          bool coldStartCalled = false;

          // Mock a fast response (2 seconds)
          when(mockClient.send(any)).thenAnswer((_) async {
            await Future.delayed(const Duration(seconds: 2));
            final responseBody = json.encode({
              'prediction': 0,
              'label': 'Non-Dyslexic',
              'confidence': 0.95,
            });
            return http.StreamedResponse(
              Stream.value(utf8.encode(responseBody)),
              200,
            );
          });

          // Act
          await apiService.predictDyslexia(
            imageBytes,
            onColdStart: () {
              coldStartCalled = true;
            },
          );

          // Assert
          expect(coldStartCalled, isFalse);
        },
      );

      test('should work without onColdStart callback', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        final responseBody = json.encode({
          'prediction': 0,
          'label': 'Non-Dyslexic',
          'confidence': 0.95,
        });

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(responseBody)),
            200,
          );
        });

        // Act & Assert - should not throw
        final result = await apiService.predictDyslexia(imageBytes);
        expect(result, isA<PredictionResult>());
      });
    });

    group('HTTP Status Code Error Handling', () {
      test('should throw ServerException for 500 status code', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([1, 2, 3]);

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode('Internal Server Error')),
            500,
          );
        });

        // Act & Assert
        expect(
          () => apiService.predictDyslexia(imageBytes),
          throwsA(
            isA<ServerException>().having(
              (e) => e.statusCode,
              'statusCode',
              500,
            ),
          ),
        );
      });

      test('should throw ServerException for 503 status code', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([1, 2, 3]);

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode('Service Unavailable')),
            503,
          );
        });

        // Act & Assert
        expect(
          () => apiService.predictDyslexia(imageBytes),
          throwsA(
            isA<ServerException>().having(
              (e) => e.statusCode,
              'statusCode',
              503,
            ),
          ),
        );
      });

      test('should throw ClientException for 404 status code', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([1, 2, 3]);

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode('Not Found')),
            404,
          );
        });

        // Act & Assert
        expect(
          () => apiService.predictDyslexia(imageBytes),
          throwsA(
            isA<ClientException>().having(
              (e) => e.statusCode,
              'statusCode',
              404,
            ),
          ),
        );
      });

      test('should throw ClientException for 400 status code', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([1, 2, 3]);

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode('Bad Request')),
            400,
          );
        });

        // Act & Assert
        expect(
          () => apiService.predictDyslexia(imageBytes),
          throwsA(
            isA<ClientException>().having(
              (e) => e.statusCode,
              'statusCode',
              400,
            ),
          ),
        );
      });

      test(
        'should throw InvalidResponseException for unexpected status code',
        () async {
          // Arrange
          final imageBytes = Uint8List.fromList([1, 2, 3]);

          when(mockClient.send(any)).thenAnswer((_) async {
            return http.StreamedResponse(
              Stream.value(utf8.encode('Redirect')),
              301,
            );
          });

          // Act & Assert
          expect(
            () => apiService.predictDyslexia(imageBytes),
            throwsA(isA<InvalidResponseException>()),
          );
        },
      );
    });

    group('Timeout Handling', () {
      test(
        'should throw TimeoutException when request exceeds 60 seconds',
        () async {
          // Arrange
          final imageBytes = Uint8List.fromList([1, 2, 3]);

          // Mock a request that never completes
          when(mockClient.send(any)).thenAnswer((_) async {
            await Future.delayed(const Duration(seconds: 65));
            final responseBody = json.encode({
              'prediction': 0,
              'label': 'Non-Dyslexic',
              'confidence': 0.95,
            });
            return http.StreamedResponse(
              Stream.value(utf8.encode(responseBody)),
              200,
            );
          });

          // Act & Assert
          expect(
            () => apiService.predictDyslexia(imageBytes),
            throwsA(isA<TimeoutException>()),
          );
        },
        timeout: const Timeout(Duration(seconds: 70)),
      );

      test('should complete successfully within timeout', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        final responseBody = json.encode({
          'prediction': 0,
          'label': 'Non-Dyslexic',
          'confidence': 0.95,
        });

        // Mock a fast response
        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(responseBody)),
            200,
          );
        });

        // Act
        final result = await apiService.predictDyslexia(imageBytes);

        // Assert
        expect(result, isA<PredictionResult>());
        expect(result.label, equals('Non-Dyslexic'));
      });
    });

    group('Network Error Handling', () {
      test('should throw NetworkException for SocketException', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([1, 2, 3]);

        when(
          mockClient.send(any),
        ).thenThrow(const SocketException('No internet connection'));

        // Act & Assert
        expect(
          () => apiService.predictDyslexia(imageBytes),
          throwsA(isA<NetworkException>()),
        );
      });

      test('should cancel cold start timer on network error', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        bool coldStartCalled = false;

        when(
          mockClient.send(any),
        ).thenThrow(const SocketException('No internet connection'));

        // Act & Assert
        try {
          await apiService.predictDyslexia(
            imageBytes,
            onColdStart: () {
              coldStartCalled = true;
            },
          );
        } catch (e) {
          // Expected to throw
        }

        // Wait a bit to ensure timer doesn't fire
        await Future.delayed(const Duration(seconds: 6));

        // Assert - cold start should not have been called
        expect(coldStartCalled, isFalse);
      });
    });

    group('Edge Cases', () {
      test('should handle empty image bytes', () async {
        // Arrange
        final imageBytes = Uint8List.fromList([]);
        final responseBody = json.encode({
          'prediction': 0,
          'label': 'Non-Dyslexic',
          'confidence': 0.95,
        });

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(responseBody)),
            200,
          );
        });

        // Act
        final result = await apiService.predictDyslexia(imageBytes);

        // Assert
        expect(result, isA<PredictionResult>());
      });

      test('should handle large image bytes (1MB)', () async {
        // Arrange
        final imageBytes = Uint8List.fromList(List.filled(1024 * 1024, 128));
        final responseBody = json.encode({
          'prediction': 1,
          'label': 'Dyslexic',
          'confidence': 0.87,
        });

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(responseBody)),
            200,
          );
        });

        // Act
        final result = await apiService.predictDyslexia(imageBytes);

        // Assert
        expect(result, isA<PredictionResult>());
      });

      test('should handle typical preprocessed image size (64x256)', () async {
        // Arrange - 64 * 256 = 16,384 bytes for grayscale
        final imageBytes = Uint8List.fromList(List.filled(16384, 128));
        final responseBody = json.encode({
          'prediction': 0,
          'label': 'Non-Dyslexic',
          'confidence': 0.95,
        });

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(responseBody)),
            200,
          );
        });

        // Act
        final result = await apiService.predictDyslexia(imageBytes);

        // Assert
        expect(result, isA<PredictionResult>());
      });

      test('should handle all black pixels', () async {
        // Arrange
        final imageBytes = Uint8List.fromList(List.filled(1000, 0));
        final responseBody = json.encode({
          'prediction': 1,
          'label': 'Dyslexic',
          'confidence': 0.75,
        });

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(responseBody)),
            200,
          );
        });

        // Act
        final result = await apiService.predictDyslexia(imageBytes);

        // Assert
        expect(result, isA<PredictionResult>());
      });

      test('should handle all white pixels', () async {
        // Arrange
        final imageBytes = Uint8List.fromList(List.filled(1000, 255));
        final responseBody = json.encode({
          'prediction': 0,
          'label': 'Non-Dyslexic',
          'confidence': 0.92,
        });

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(responseBody)),
            200,
          );
        });

        // Act
        final result = await apiService.predictDyslexia(imageBytes);

        // Assert
        expect(result, isA<PredictionResult>());
      });
    });

    group('Exception Classes', () {
      test('NetworkException should have correct message', () {
        final exception = NetworkException('No connection');
        expect(exception.message, equals('No connection'));
        expect(exception.toString(), contains('NetworkException'));
        expect(exception.toString(), contains('No connection'));
      });

      test('ServerException should have message and status code', () {
        final exception = ServerException('Internal error', statusCode: 500);
        expect(exception.message, equals('Internal error'));
        expect(exception.statusCode, equals(500));
        expect(exception.toString(), contains('ServerException'));
        expect(exception.toString(), contains('500'));
      });

      test('ClientException should have message and status code', () {
        final exception = ClientException('Bad request', statusCode: 400);
        expect(exception.message, equals('Bad request'));
        expect(exception.statusCode, equals(400));
        expect(exception.toString(), contains('ClientException'));
        expect(exception.toString(), contains('400'));
      });

      test('InvalidResponseException should have correct message', () {
        final exception = InvalidResponseException('Parse error');
        expect(exception.message, equals('Parse error'));
        expect(exception.toString(), contains('InvalidResponseException'));
        expect(exception.toString(), contains('Parse error'));
      });
    });
  });
}
