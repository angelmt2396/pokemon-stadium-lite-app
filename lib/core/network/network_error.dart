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

    final dioMessage = _sanitizeMessage(error.message);
    if (dioMessage != null &&
        error.type != DioExceptionType.badResponse &&
        error.type != DioExceptionType.connectionError &&
        error.type != DioExceptionType.connectionTimeout &&
        error.type != DioExceptionType.sendTimeout &&
        error.type != DioExceptionType.receiveTimeout &&
        error.type != DioExceptionType.cancel) {
      return dioMessage;
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

  final extractedMessage = _extractErrorMessage(error);
  if (extractedMessage != null && extractedMessage.isNotEmpty) {
    return extractedMessage;
  }

  return fallbackMessage;
}

bool isUnauthorizedNetworkError(Object error) {
  return error is DioException && error.response?.statusCode == 401;
}

bool isExpiredSessionError(Object error) {
  if (isUnauthorizedNetworkError(error)) {
    return true;
  }

  final message = _extractErrorMessage(error)?.toLowerCase();
  return message != null && message.contains('invalid or expired session token');
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
  if (data is String) {
    return _sanitizeMessage(data);
  }

  if (data is Map<String, dynamic>) {
    for (final key in const ['message', 'error', 'detail', 'description', 'title']) {
      final candidate = _extractResponseMessage(data[key]);
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    }

    for (final key in const ['data', 'details', 'errors']) {
      final candidate = _extractResponseMessage(data[key]);
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    }
  }

  if (data is Map && data is! Map<String, dynamic>) {
    final map = Map<String, dynamic>.from(data);
    return _extractResponseMessage(map);
  }

  if (data is List) {
    for (final entry in data) {
      final candidate = _extractResponseMessage(entry);
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    }
  }

  return null;
}

String? _extractErrorMessage(Object error) {
  if (error is String) {
    return _sanitizeMessage(error);
  }

  if (error is Map<String, dynamic>) {
    return _extractResponseMessage(error);
  }

  if (error is Map && error is! Map<String, dynamic>) {
    return _extractResponseMessage(Map<String, dynamic>.from(error));
  }

  if (error is Exception || error is Error) {
    return _sanitizeMessage(error.toString());
  }

  return null;
}

String? _sanitizeMessage(String? rawMessage) {
  if (rawMessage == null) {
    return null;
  }

  final message = rawMessage.trim();
  if (message.isEmpty || message == 'null') {
    return null;
  }

  final withoutExceptionPrefix = message.replaceFirst(RegExp(r'^Exception:\s*'), '');
  final firstLine = withoutExceptionPrefix
      .split('\n')
      .map((line) => line.trim())
      .firstWhere((line) => line.isNotEmpty, orElse: () => '');

  if (firstLine.isEmpty) {
    return null;
  }

  final lowerFirstLine = firstLine.toLowerCase();
  if (lowerFirstLine.startsWith('dioexception') ||
      lowerFirstLine.startsWith('socketexception:') ||
      lowerFirstLine.startsWith('websocketexception:') ||
      lowerFirstLine.startsWith('httpexception:') ||
      lowerFirstLine.startsWith('transporterror:') ||
      lowerFirstLine == 'xmlhttprequest error') {
    return null;
  }

  return firstLine;
}
