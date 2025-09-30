import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/local_storage_service.dart';

part 'user_event.dart';
part 'user_state.dart';

class UserListBloc extends Bloc<UserListEvent, UserListState> {
  final UserRepository userRepository;

  UserListBloc({required this.userRepository}) : super(UserListInitial()) {
    on<FetchUsers>(_onFetchUsers);
    on<RefreshUsers>(_onRefreshUsers);
  }

  Future<void> _onFetchUsers(
    FetchUsers event,
    Emitter<UserListState> emit,
  ) async {
    emit(UserListLoading());

    try {
      final users = await userRepository.getUsers(
        forceRefresh: event.forceRefresh,
      );
      emit(UserListLoaded(users: users, isFromCache: false));
    } catch (e) {
      final cachedUsers = await LocalStorageService.getCachedUsers();
      if (cachedUsers.isNotEmpty) {
        emit(UserListLoaded(users: cachedUsers, isFromCache: true));
      } else {
        emit(UserListError(message: e.toString(), cachedUsers: cachedUsers));
      }
    }
  }

  Future<void> _onRefreshUsers(
    RefreshUsers event,
    Emitter<UserListState> emit,
  ) async {
    try {
      final users = await userRepository.getUsers(forceRefresh: true);
      emit(UserListLoaded(users: users, isFromCache: false));
    } catch (e) {
      final cachedUsers = await LocalStorageService.getCachedUsers();
      emit(UserListError(message: e.toString(), cachedUsers: cachedUsers));
    }
  }
}
