abstract class AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String username, password;
  AuthLoginRequested(this.username, this.password);
}

class AuthLogoutRequested extends AuthEvent {}
