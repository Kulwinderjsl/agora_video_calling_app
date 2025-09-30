part of 'video_call_bloc.dart';

class VideoCallState extends Equatable {
  final VideoCallStatus status;
  final bool isAudioMuted;
  final bool isVideoMuted;
  final bool isScreenSharing;
  final bool isJoined;
  final int? localUid;
  final List<int> remoteUids;
  final int? screenShareUid;
  final String? error;
  final PermissionStatus permissionStatus;
  final String? channelName;
  final DateTime? lastUpdated;

  const VideoCallState({
    this.status = VideoCallStatus.initial,
    this.isAudioMuted = false,
    this.isVideoMuted = false,
    this.isScreenSharing = false,
    this.isJoined = false,
    this.localUid,
    this.remoteUids = const [],
    this.screenShareUid,
    this.error,
    this.permissionStatus = PermissionStatus.unknown,
    this.channelName,
    this.lastUpdated,
  });

  VideoCallState copyWith({
    VideoCallStatus? status,
    bool? isAudioMuted,
    bool? isVideoMuted,
    bool? isScreenSharing,
    bool? isJoined,
    int? localUid,
    List<int>? remoteUids,
    int? screenShareUid,
    String? error,
    PermissionStatus? permissionStatus,
    String? channelName,
    DateTime? lastUpdated,
  }) {
    return VideoCallState(
      status: status ?? this.status,
      isAudioMuted: isAudioMuted ?? this.isAudioMuted,
      isVideoMuted: isVideoMuted ?? this.isVideoMuted,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      isJoined: isJoined ?? this.isJoined,
      localUid: localUid ?? this.localUid,
      remoteUids: remoteUids ?? this.remoteUids,
      screenShareUid: screenShareUid ?? this.screenShareUid,
      error: error ?? this.error,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      channelName: channelName ?? this.channelName,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  bool get isInCall =>
      status == VideoCallStatus.connected ||
      status == VideoCallStatus.screenSharing;

  bool get isLoading =>
      status == VideoCallStatus.loading ||
      status == VideoCallStatus.checkingPermissions ||
      status == VideoCallStatus.initializingAgora ||
      status == VideoCallStatus.joiningChannel;

  bool get hasError => status == VideoCallStatus.error && error != null;

  bool get hasPermissions => permissionStatus == PermissionStatus.granted;

  @override
  List<Object?> get props => [
    status,
    isAudioMuted,
    isVideoMuted,
    isScreenSharing,
    isJoined,
    localUid,
    remoteUids,
    screenShareUid,
    error,
    permissionStatus,
    channelName,
    lastUpdated,
  ];
}

enum VideoCallStatus {
  initial,
  loading,
  checkingPermissions,
  permissionsGranted,
  permissionsDenied,
  initializingAgora,
  joiningChannel,
  connected,
  screenSharing,
  disconnecting,
  disconnected,
  error,
}

enum PermissionStatus { unknown, granted, denied, permanentlyDenied }
