part of 'video_call_bloc.dart';

abstract class VideoCallEvent extends Equatable {
  const VideoCallEvent();

  @override
  List<Object> get props => [];
}

class InitializeVideoCallEvent extends VideoCallEvent {
  final String channelName;

  const InitializeVideoCallEvent({required this.channelName});

  @override
  List<Object> get props => [channelName];
}

class CheckPermissionsEvent extends VideoCallEvent {}

class RequestPermissionsEvent extends VideoCallEvent {}

class JoinChannelEvent extends VideoCallEvent {
  final String channelName;

  const JoinChannelEvent({required this.channelName});

  @override
  List<Object> get props => [channelName];
}

class LeaveChannelEvent extends VideoCallEvent {}

class ToggleAudioEvent extends VideoCallEvent {}

class ToggleVideoEvent extends VideoCallEvent {}

class StartScreenShareEvent extends VideoCallEvent {}

class StopScreenShareEvent extends VideoCallEvent {}

class SwitchCameraEvent extends VideoCallEvent {}

class UserJoinedEvent extends VideoCallEvent {
  final int uid;

  const UserJoinedEvent(this.uid);

  @override
  List<Object> get props => [uid];
}

class UserLeftEvent extends VideoCallEvent {
  final int uid;

  const UserLeftEvent(this.uid);

  @override
  List<Object> get props => [uid];
}

class CallJoinedEvent extends VideoCallEvent {
  final int localUid;

  const CallJoinedEvent(this.localUid);

  @override
  List<Object> get props => [localUid];
}

class ScreenShareStartedEvent extends VideoCallEvent {
  final int screenShareUid;

  const ScreenShareStartedEvent(this.screenShareUid);

  @override
  List<Object> get props => [screenShareUid];
}

class ScreenShareStoppedEvent extends VideoCallEvent {}

class PermissionStatusChangedEvent extends VideoCallEvent {
  final PermissionStatus status;

  const PermissionStatusChangedEvent(this.status);

  @override
  List<Object> get props => [status];
}

class ErrorOccurredEvent extends VideoCallEvent {
  final String error;

  const ErrorOccurredEvent(this.error);

  @override
  List<Object> get props => [error];
}

class ResetVideoCallEvent extends VideoCallEvent {}

class UpdateRemoteUidsEvent extends VideoCallEvent {
  final List<int> remoteUids;

  const UpdateRemoteUidsEvent(this.remoteUids);

  @override
  List<Object> get props => [remoteUids];
}

class UpdateScreenShareUidEvent extends VideoCallEvent {
  final int? screenShareUid;

  const UpdateScreenShareUidEvent(this.screenShareUid);

  @override
  List<Object> get props => [if (screenShareUid != null) screenShareUid!];
}
