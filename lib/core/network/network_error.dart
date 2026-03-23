import 'package:dio/dio.dart';

String normalizeNetworkError(
  Object error, {
  required bool isEs,
  required String fallbackMessage,
}) {
  if (error is DioException) {
    final responseMessage = _extractResponseMessage(error.response?.data);
    if (responseMessage != null && responseMessage.isNotEmpty) {
      return responseMessage;
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => isEs
          ? 'Se agotó el tiempo de espera con el backend.'
          : 'The backend request timed out.',
      DioExceptionType.connectionError => isEs
          ? 'No se pudo conectar con el backend.'
          : 'Could not connect to the backend.',
      DioExceptionType.badResponse => _messageForStatusCode(
          error.response?.statusCode,
          isEs: isEs,
          fallbackMessage: fallbackMessage,
        ),
      DioExceptionType.cancel => isEs
          ? 'La petición fue cancelada.'
          : 'The request was cancelled.',
      _ => fallbackMessage,
    };
  }

  if (error is Exception) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  return fallbackMessage;
}

bool isUnauthorizedNetworkError(Object error) {
  return error is DioException && error.response?.statusCode == 401;
}

String _messageForStatusCode(
  int? statusCode, {
  required bool isEs,
  required String fallbackMessage,
}) {
  return switch (statusCode) {
    400 => isEs
        ? 'La petición no fue válida.'
        : 'The request was not valid.',
    401 => isEs
        ? 'La sesión ya no es válida. Vuelve a iniciar sesión.'
        : 'The session is no longer valid. Sign in again.',
    403 => isEs
        ? 'No tienes permisos para realizar esta acción.'
        : 'You do not have permission to perform this action.',
    404 => isEs
        ? 'El recurso solicitado no existe.'
        : 'The requested resource does not exist.',
    409 => isEs
        ? 'La acción entró en conflicto con el estado actual.'
        : 'The action conflicted with the current state.',
    500 => isEs
        ? 'El backend falló al procesar la petición.'
        : 'The backend failed while processing the request.',
    _ => fallbackMessage,
  };
}

String? _extractResponseMessage(dynamic data) {
  if (data is Map<String, dynamic>) {
    final candidate = data['message'] ?? data['error'];
    if (candidate is String) {
      return candidate;
    }

    final nestedData = data['data'];
    if (nestedData is Map<String, dynamic>) {
      final nestedCandidate = nestedData['message'] ?? nestedData['error'];
      if (nestedCandidate is String) {
        return nestedCandidate;
      }
    }
  }

  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    return _extractResponseMessage(map);
  }

  return null;
}
