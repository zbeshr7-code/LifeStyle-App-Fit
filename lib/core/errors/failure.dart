sealed class Failure {
  const Failure(this.message);

  final String message;
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'network_error']);
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'server_error']);
}

final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'auth_error']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
