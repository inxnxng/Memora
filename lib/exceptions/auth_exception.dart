/// A custom exception for authentication errors.
class AuthServiceException implements Exception {
  final String message;
  AuthServiceException(this.message);

  @override
  String toString() => message;
}
