import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/user_model.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
  }

  FutureOr<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    await Future.delayed(const Duration(seconds: 2));

    if (event.email == 'user@example.com' && event.password == 'password') {
      emit(
        AuthSuccess(
          User(
            id: 1,
            email: event.email,
            name: 'Test User',
            avatarUrl: 'https://reqres.in/img/faces/1-image.jpg',
            username: 'test',
          ),
        ),
      );
    } else {
      emit(const AuthFailure('Invalid credentials'));
    }
  }

  FutureOr<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) {
    emit(AuthInitial());
  }
}
