import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';
// naber fıstık
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;
  AuthBloc(this._repo) : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final token = await _repo.logIn(
        username: event.username,
        password: event.password,
      );
      emit(AuthAuthenticated(token));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await _repo.logOut();
    emit(AuthUnauthenticated());
  }
}
