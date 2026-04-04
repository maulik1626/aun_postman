sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}

class TimeoutException extends AppException {
  const TimeoutException([String message = 'Request timed out'])
      : super(message);
}

class ParseException extends AppException {
  const ParseException(super.message, {this.body});
  final String? body;
}

class StorageException extends AppException {
  const StorageException(super.message);
}

class CancelException extends AppException {
  const CancelException([String message = 'Request cancelled']) : super(message);
}

class ImportException extends AppException {
  const ImportException(super.message);
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}

class UnknownException extends AppException {
  const UnknownException([String message = 'An unexpected error occurred'])
      : super(message);
}
