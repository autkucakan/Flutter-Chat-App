abstract class AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String username, password;
  AuthLoginRequested(this.username, this.password);
}
// selam
class AuthLogoutRequested extends AuthEvent {}
