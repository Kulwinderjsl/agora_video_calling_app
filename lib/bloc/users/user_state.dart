part of 'user_bloc.dart';

@immutable
sealed class UserListState extends Equatable {
  const UserListState();

  @override
  List<Object> get props => [];
}

final class UserListInitial extends UserListState {}

final class UserListLoading extends UserListState {}

final class UserListLoaded extends UserListState {
  final List<User> users;
  final bool isFromCache;

  const UserListLoaded({required this.users, this.isFromCache = false});

  @override
  List<Object> get props => [users, isFromCache];
}

final class UserListError extends UserListState {
  final String message;
  final List<User>? cachedUsers;

  const UserListError({required this.message, this.cachedUsers});

  @override
  List<Object> get props => [message];
}
