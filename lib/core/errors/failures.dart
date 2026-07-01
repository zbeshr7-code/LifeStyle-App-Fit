abstract class Failure {
  final String message;
  final int? statusCode;

  Failure(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class AuthFailure extends Failure {
  AuthFailure(String message, {int? statusCode}) : super(message, statusCode: statusCode);
}

class ServerFailure extends Failure {
  ServerFailure(String message, {int? statusCode}) : super(message, statusCode: statusCode);
}

class NetworkFailure extends Failure {
  NetworkFailure([String message = 'No Internet Connection']) : super(message);
}

class ValidationFailure extends Failure {
  ValidationFailure(String message) : super(message);
}
