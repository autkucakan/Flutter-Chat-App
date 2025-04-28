// lib/bloc/auth_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/services/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;
  String? _token;

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
      final user = await _repo.logIn(
        username: event.username,
        password: event.password,
      );
      _token = user.token; // cache in memory if you need it elsewhere
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _repo.logOut();
      _token = null;
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }
}