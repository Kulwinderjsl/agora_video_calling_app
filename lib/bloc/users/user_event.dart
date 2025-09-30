part of 'user_bloc.dart';

@immutable
sealed class UserListEvent extends Equatable {
  const UserListEvent();

  @override
  List<Object> get props => [];
}

final class FetchUsers extends UserListEvent {
  final bool forceRefresh;

  const FetchUsers({this.forceRefresh = false});

  @override
  List<Object> get props => [forceRefresh];
}

final class RefreshUsers extends UserListEvent {}
