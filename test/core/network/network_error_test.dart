import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemon_stadium_lite_app/core/network/network_error.dart';

void main() {
  group('normalizeNetworkError', () {
    final requestOptions = RequestOptions(path: '/test');

    test('returns backend message from top-level http payload', () {
      final error = DioException(
        requestOptions: requestOptions,
        response: Response<Map<String, dynamic>>(
          requestOptions: requestOptions,
          statusCode: 409,
          data: const {
            'success': false,
            'message': 'Nickname is already in use',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      expect(
        normalizeNetworkError(
          error,
          isEs: true,
          fallbackMessage: 'fallback',
        ),
        'Nickname is already in use',
      );
    });

    test('returns nested backend message from payload data', () {
      final error = DioException(
        requestOptions: requestOptions,
        response: Response<Map<String, dynamic>>(
          requestOptions: requestOptions,
          statusCode: 401,
          data: const {
            'success': false,
            'data': {
              'message': 'Invalid or expired session token',
            },
          },
        ),
        type: DioExceptionType.badResponse,
      );

      expect(
        normalizeNetworkError(
          error,
          isEs: true,
          fallbackMessage: 'fallback',
        ),
        'Invalid or expired session token',
      );
    });

    test('maps http status when payload has no user-facing message', () {
      final error = DioException(
        requestOptions: requestOptions,
        response: Response<Map<String, dynamic>>(
          requestOptions: requestOptions,
          statusCode: 404,
          data: const {'success': false},
        ),
        type: DioExceptionType.badResponse,
      );

      expect(
        normalizeNetworkError(
          error,
          isEs: true,
          fallbackMessage: 'fallback',
        ),
        'El recurso solicitado no existe.',
      );
    });

    test('maps timeout errors to a localized transport message', () {
      final error = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionTimeout,
      );

      expect(
        normalizeNetworkError(
          error,
          isEs: true,
          fallbackMessage: 'fallback',
        ),
        'Se agotó el tiempo de espera con el backend.',
      );
    });

    test('returns socket ack message from raw map payload', () {
      expect(
        normalizeNetworkError(
          {
            'ok': false,
            'message': 'Socket session is not authenticated',
          },
          isEs: true,
          fallbackMessage: 'fallback',
        ),
        'Socket session is not authenticated',
      );
    });

    test('falls back instead of surfacing raw DioException text', () {
      expect(
        normalizeNetworkError(
          Exception(
            'DioException [bad response]: '
            'This exception was thrown because the response has a status code of 500.',
          ),
          isEs: true,
          fallbackMessage: 'No se pudo consultar el backend.',
        ),
        'No se pudo consultar el backend.',
      );
    });
  });

  group('isExpiredSessionError', () {
    final requestOptions = RequestOptions(path: '/test');

    test('detects http 401 responses as expired session', () {
      final error = DioException(
        requestOptions: requestOptions,
        response: Response<Map<String, dynamic>>(
          requestOptions: requestOptions,
          statusCode: 401,
          data: const {
            'success': false,
            'message': 'Invalid or expired session token',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      expect(isExpiredSessionError(error), isTrue);
    });

    test('detects socket auth message as expired session', () {
      expect(
        isExpiredSessionError(
          Exception('Invalid or expired session token'),
        ),
        isTrue,
      );
    });
  });
}
