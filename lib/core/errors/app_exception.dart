class AppException implements Exception {
  const AppException(this.userMessage, {this.debugCode, this.cause});

  /// Safe to show in the UI. Never include stack traces or secrets.
  final String userMessage;

  /// Optional internal identifier for logs (not shown to users).
  final String? debugCode;

  final Object? cause;

  @override
  String toString() => debugCode == null ? userMessage : '$userMessage ($debugCode)';
}

class ValidationException extends AppException {
  const ValidationException(super.userMessage, {super.debugCode, super.cause});
}

class NetworkException extends AppException {
  const NetworkException(super.userMessage, {super.debugCode, super.cause});
}
