import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/agora_service.dart';

part 'video_call_event.dart';
part 'video_call_state.dart';

class VideoCallBloc extends Bloc<VideoCallEvent, VideoCallState> {
  final AgoraService agoraService;

  VideoCallBloc({required this.agoraService}) : super(const VideoCallState()) {
    on<InitializeVideoCallEvent>(_onInitializeVideoCall);
    on<CheckPermissionsEvent>(_onCheckPermissions);
    on<RequestPermissionsEvent>(_onRequestPermissions);
    on<JoinChannelEvent>(_onJoinChannel);
    on<LeaveChannelEvent>(_onLeaveChannel);
    on<ToggleAudioEvent>(_onToggleAudio);
    on<ToggleVideoEvent>(_onToggleVideo);
    on<StartScreenShareEvent>(_onStartScreenShare);
    on<StopScreenShareEvent>(_onStopScreenShare);
    on<SwitchCameraEvent>(_onSwitchCamera);
    on<UserJoinedEvent>(_onUserJoined);
    on<UserLeftEvent>(_onUserLeft);
    on<CallJoinedEvent>(_onCallJoined);
    on<ScreenShareStartedEvent>(_onScreenShareStarted);
    on<ScreenShareStoppedEvent>(_onScreenShareStopped);
    on<ErrorOccurredEvent>(_onErrorOccurred);
    on<ResetVideoCallEvent>(_onResetVideoCall);
  }

  FutureOr<void> _onInitializeVideoCall(
    InitializeVideoCallEvent event,
    Emitter<VideoCallState> emit,
  ) async {
    print('Initializing video call for channel: ${event.channelName}');
    emit(
      state.copyWith(
        status: VideoCallStatus.loading,
        channelName: event.channelName,
        error: null,
      ),
    );

    add(CheckPermissionsEvent());
  }

  FutureOr<void> _onCheckPermissions(
    CheckPermissionsEvent event,
    Emitter<VideoCallState> emit,
  ) async {
    print('Checking permissions...');
    emit(state.copyWith(status: VideoCallStatus.checkingPermissions));

    try {
      final hasPermissions = await agoraService.checkPermissions();
      print('Permissions check result: $hasPermissions');

      final permissionStatus = hasPermissions
          ? PermissionStatus.granted
          : PermissionStatus.denied;

      emit(
        state.copyWith(
          permissionStatus: permissionStatus,
          status: hasPermissions
              ? VideoCallStatus.permissionsGranted
              : VideoCallStatus.permissionsDenied,
        ),
      );

      if (hasPermissions && state.channelName != null) {
        print('Permissions granted, joining channel: ${state.channelName}');
        add(JoinChannelEvent(channelName: state.channelName!));
      } else if (!hasPermissions) {
        print('Permissions denied, requesting permissions...');
        add(RequestPermissionsEvent());
      }
    } catch (e) {
      print('Error checking permissions: $e');
      add(ErrorOccurredEvent('Failed to check permissions: $e'));
    }
  }

  FutureOr<void> _onRequestPermissions(
    RequestPermissionsEvent event,
    Emitter<VideoCallState> emit,
  ) async {
    print('Requesting permissions...');
    emit(state.copyWith(status: VideoCallStatus.checkingPermissions));

    try {
      final hasPermissions = await agoraService.requestPermissions();
      print('Permission request result: $hasPermissions');

      final permissionStatus = hasPermissions
          ? PermissionStatus.granted
          : PermissionStatus.denied;

      emit(
        state.copyWith(
          permissionStatus: permissionStatus,
          status: hasPermissions
              ? VideoCallStatus.permissionsGranted
              : VideoCallStatus.permissionsDenied,
        ),
      );

      if (hasPermissions && state.channelName != null) {
        print('Permissions granted after request, joining channel');
        add(JoinChannelEvent(channelName: state.channelName!));
      } else if (!hasPermissions) {
        add(
          ErrorOccurredEvent(
            'Please grant camera and microphone permissions to start video call',
          ),
        );
      }
    } catch (e) {
      print('Error requesting permissions: $e');
      add(ErrorOccurredEvent('Failed to request permissions: $e'));
    }
  }

  FutureOr<void> _onJoinChannel(
    JoinChannelEvent event,
    Emitter<VideoCallState> emit,
  ) async {
    print('Joining channel: ${event.channelName}');
    emit(
      state.copyWith(
        status: VideoCallStatus.initializingAgora,
        channelName: event.channelName,
      ),
    );

    try {
      await agoraService.initialize();
      emit(state.copyWith(status: VideoCallStatus.joiningChannel));

      await agoraService.joinChannel(event.channelName);
      print('Channel join request sent successfully');
    } catch (e) {
      print('Error joining channel: $e');
      add(ErrorOccurredEvent('Failed to join channel: $e'));
    }
  }

  FutureOr<void> _onLeaveChannel(
    LeaveChannelEvent event,
    Emitter<VideoCallState> emit,
  ) async {
    print('Leaving channel...');
    emit(state.copyWith(status: VideoCallStatus.disconnecting));

    try {
      if (state.isScreenSharing) {
        await agoraService.stopScreenSharing();
      }

      await agoraService.leaveChannel();
      await agoraService.dispose();

      emit(const VideoCallState(status: VideoCallStatus.disconnected));
      print('Channel left successfully');
    } catch (e) {
      print('Error leaving channel: $e');
      add(ErrorOccurredEvent('Failed to leave channel: $e'));
    }
  }

  FutureOr<void> _onToggleAudio(
    ToggleAudioEvent event,
    Emitter<VideoCallState> emit,
  ) async {
    if (state.status != VideoCallStatus.connected &&
        state.status != VideoCallStatus.screenSharing) {
      return;
    }

    final newAudioState = !state.isAudioMuted;

    try {
      await agoraService.toggleAudioMute(newAudioState);
      emit(state.copyWith(isAudioMuted: newAudioState));
    } catch (e) {
      print('Error toggling audio: $e');
      add(ErrorOccurredEvent('Failed to toggle audio: $e'));
    }
  }

  FutureOr<void> _onToggleVideo(
    ToggleVideoEvent event,
    Emitter<VideoCallState> emit,
  ) async {
    if (state.status != VideoCallStatus.connected &&
        state.status != VideoCallStatus.screenSharing) {
      return;
    }

    final newVideoState = !state.isVideoMuted;

    try {
      await agoraService.toggleVideoMute(newVideoState);
      emit(state.copyWith(isVideoMuted: newVideoState));
    } catch (e) {
      print('Error toggling video: $e');
      add(ErrorOccurredEvent('Failed to toggle video: $e'));
    }
  }

  FutureOr<void> _onStartScreenShare(
    StartScreenShareEvent event,
    Emitter<VideoCallState> emit,
  ) async {
    if (state.status != VideoCallStatus.connected) {
      return;
    }

    try {
      await agoraService.startScreenSharing();
    } catch (e) {
      print('Error starting screen sharing: $e');
      add(ErrorOccurredEvent('Failed to start screen sharing: $e'));
    }
  }

  FutureOr<void> _onStopScreenShare(
    StopScreenShareEvent event,
    Emitter<VideoCallState> emit,
  ) async {
    if (!state.isScreenSharing) {
      return;
    }

    try {
      await agoraService.stopScreenSharing();
    } catch (e) {
      print('Error stopping screen sharing: $e');
      add(ErrorOccurredEvent('Failed to stop screen sharing: $e'));
    }
  }

  FutureOr<void> _onSwitchCamera(
    SwitchCameraEvent event,
    Emitter<VideoCallState> emit,
  ) async {
    if (state.status != VideoCallStatus.connected &&
        state.status != VideoCallStatus.screenSharing) {
      return;
    }

    try {
      await agoraService.switchCamera();
    } catch (e) {
      print('Error switching camera: $e');
      add(ErrorOccurredEvent('Failed to switch camera: $e'));
    }
  }

  FutureOr<void> _onUserJoined(
    UserJoinedEvent event,
    Emitter<VideoCallState> emit,
  ) {
    print('User joined: ${event.uid}');
    final updatedUids = List<int>.from(state.remoteUids)..add(event.uid);
    emit(state.copyWith(remoteUids: updatedUids));
  }

  FutureOr<void> _onUserLeft(
    UserLeftEvent event,
    Emitter<VideoCallState> emit,
  ) {
    print('User left: ${event.uid}');
    final updatedUids = List<int>.from(state.remoteUids)..remove(event.uid);
    final updatedScreenShareUid = state.screenShareUid == event.uid
        ? null
        : state.screenShareUid;

    emit(
      state.copyWith(
        remoteUids: updatedUids,
        screenShareUid: updatedScreenShareUid,
      ),
    );
  }

  FutureOr<void> _onCallJoined(
    CallJoinedEvent event,
    Emitter<VideoCallState> emit,
  ) {
    print('Call joined successfully, local UID: ${event.localUid}');
    emit(
      state.copyWith(
        status: VideoCallStatus.connected,
        isJoined: true,
        localUid: event.localUid,
        error: null,
      ),
    );
  }

  FutureOr<void> _onScreenShareStarted(
    ScreenShareStartedEvent event,
    Emitter<VideoCallState> emit,
  ) {
    print('Screen sharing started with UID: ${event.screenShareUid}');
    emit(
      state.copyWith(
        status: VideoCallStatus.screenSharing,
        isScreenSharing: true,
        screenShareUid: event.screenShareUid,
        isVideoMuted: true,
      ),
    );
  }

  FutureOr<void> _onScreenShareStopped(
    ScreenShareStoppedEvent event,
    Emitter<VideoCallState> emit,
  ) {
    print('Screen sharing stopped');
    emit(
      state.copyWith(
        status: VideoCallStatus.connected,
        isScreenSharing: false,
        screenShareUid: null,
        isVideoMuted: false,
      ),
    );
  }

  FutureOr<void> _onErrorOccurred(
    ErrorOccurredEvent event,
    Emitter<VideoCallState> emit,
  ) {
    print('Error occurred: ${event.error}');
    emit(state.copyWith(status: VideoCallStatus.error, error: event.error));
  }

  FutureOr<void> _onResetVideoCall(
    ResetVideoCallEvent event,
    Emitter<VideoCallState> emit,
  ) {
    print('Resetting video call state');
    emit(const VideoCallState());
  }
}
