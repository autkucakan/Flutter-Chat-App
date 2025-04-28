abstract class AuthState {}
class AuthInitial        extends AuthState {}
class AuthLoading        extends AuthState {}
/// Now holds just the token
class AuthAuthenticated  extends AuthState {
  final String token;
  AuthAuthenticated(this.token);
}
class AuthUnauthenticated extends AuthState {}
class AuthFailure        extends AuthState {
  final String error;
  AuthFailure(this.error);
}
