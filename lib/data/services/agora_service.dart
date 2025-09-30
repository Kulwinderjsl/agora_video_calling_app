import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import '../../bloc/video_call/video_call_bloc.dart';
import '../../utils/constants.dart';
import '../../utils/permissions.dart';

class AgoraService {
  RtcEngine? _agoraEngine;
  VideoCallBloc? _videoCallBloc;
  bool _isInitialized = false;
  bool _isJoined = false;
  bool _isScreenSharing = false;

  void setVideoCallBloc(VideoCallBloc bloc) {
    _videoCallBloc = bloc;
  }

  Future<bool> checkPermissions() async {
    try {
      final permissions = await PermissionService.getPermissionStatus();

      return permissions['camera'] == true && permissions['microphone'] == true;
    } catch (e) {
      print(' Error checking permissions: $e');
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      return await PermissionService.requestAllPermissions();
    } catch (e) {
      print(' Error requesting permissions: $e');
      return false;
    }
  }

  Future<void> initialize() async {
    try {
      if (_isInitialized) {
        print(' Agora already initialized');
        return;
      }

      _agoraEngine = createAgoraRtcEngine();

      await _agoraEngine!.initialize(
        RtcEngineContext(appId: AppConstants.agoraAppId),
      );

      await _agoraEngine!.enableVideo();

      _setupEngineEventHandlers();
      await _agoraEngine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 360),
          frameRate: 15,
          bitrate: 0,
        ),
      );

      await _agoraEngine!.enableDualStreamMode(enabled: true);

      await _agoraEngine!.startPreview();

      _isInitialized = true;
      print(' Agora initialization completed successfully');
    } catch (e) {
      print(' Error initializing Agora: $e');
      _addError('Failed to initialize Agora: $e');
      rethrow;
    }
  }

  void _setupEngineEventHandlers() {
    _agoraEngine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          _isJoined = true;

          Future.delayed(const Duration(milliseconds: 100), () {
            _videoCallBloc?.add(CallJoinedEvent(connection.localUid!));
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          print(' Remote user joined: $remoteUid');
          _videoCallBloc?.add(UserJoinedEvent(remoteUid));
        },
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              print(' Remote user left: $remoteUid, reason: $reason');
              _videoCallBloc?.add(UserLeftEvent(remoteUid));
            },
        onError: (ErrorCodeType errorCode, String message) {
          print(' Agora Error: $errorCode, $message');
          _addError('Agora Error: $errorCode - $message');
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          _isJoined = false;
        },
        onRemoteVideoStateChanged:
            (
              RtcConnection connection,
              int remoteUid,
              RemoteVideoState state,
              RemoteVideoStateReason reason,
              int elapsed,
            ) {
              if (state == RemoteVideoState.remoteVideoStateStarting) {
                print(' Remote video starting for UID: $remoteUid');
              } else if (state == RemoteVideoState.remoteVideoStateDecoding) {
                print(' Remote video decoding for UID: $remoteUid');
              }
            },

        onConnectionStateChanged:
            (
              RtcConnection connection,
              ConnectionStateType state,
              ConnectionChangedReasonType reason,
            ) {
              print(' Connection state changed: $state, reason: $reason');
            },
      ),
    );
  }

  Future<void> joinChannel(String channelName) async {
    try {
      if (!_isInitialized) {
        print(' Agora not initialized, initializing now...');
        await initialize();
      }

      final token = AppConstants.tempToken.isEmpty
          ? null
          : AppConstants.tempToken;
      print(' Using token: ${token != null ? 'Yes' : 'No'}');

      await _agoraEngine!.joinChannel(
        token: token!,
        channelId: channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          publishScreenCaptureVideo: false,
          publishScreenCaptureAudio: false,
        ),
      );
      print(' Join channel request sent for: $channelName');
    } catch (e) {
      print(' Error joining channel: $e');
      _addError('Failed to join channel: $e');
      rethrow;
    }
  }

  Future<void> startScreenSharing() async {
    try {
      print('Starting screen sharing...');

      if (!_isJoined) {
        throw Exception('Must be in a call to start screen sharing');
      }

      final hasPermission =
          await PermissionService.requestScreenSharingPermission();
      if (!hasPermission) {
        throw Exception(
          'Screen recording permission is required for screen sharing',
        );
      }

      // Start screen capture
      await _agoraEngine!.startScreenCapture(
        const ScreenCaptureParameters2(
          captureVideo: true,
          captureAudio: false,
          videoParams: ScreenVideoParameters(
            dimensions: VideoDimensions(width: 1280, height: 720),
            frameRate: 15,
            bitrate: 2000,
          ),
        ),
      );

      await _agoraEngine!.updateChannelMediaOptions(
        const ChannelMediaOptions(
          publishScreenCaptureVideo: true,
          publishScreenCaptureAudio: false,
          publishCameraTrack: false,
          publishMicrophoneTrack: true,
        ),
      );

      _isScreenSharing = true;

      final screenShareUid = 1000000;
      _videoCallBloc?.add(ScreenShareStartedEvent(screenShareUid));
      print('Screen sharing started successfully');
    } catch (e) {
      print('Error starting screen sharing: $e');
      _addError('Failed to start screen sharing: $e');
      rethrow;
    }
  }

  Future<void> stopScreenSharing() async {
    try {
      await _agoraEngine!.stopScreenCapture();
      print('Screen capture stopped');

      await _agoraEngine!.updateChannelMediaOptions(
        const ChannelMediaOptions(
          publishScreenCaptureVideo: false,
          publishScreenCaptureAudio: false,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
        ),
      );

      _isScreenSharing = false;
      _videoCallBloc?.add(ScreenShareStoppedEvent());
      print('Screen sharing stopped successfully');
    } catch (e) {
      print('Error stopping screen sharing: $e');
      _addError('Failed to stop screen sharing: $e');
      rethrow;
    }
  }

  Future<void> leaveChannel() async {
    try {
      print('Leaving channel...');

      if (_isScreenSharing) {
        await stopScreenSharing();
      }

      if (_isJoined) {
        await _agoraEngine!.leaveChannel();
        _isJoined = false;
        print('Channel left successfully');
      }
    } catch (e) {
      print('Error leaving channel: $e');
      _addError('Error leaving channel: $e');
    }
  }

  Future<void> toggleAudioMute(bool mute) async {
    try {
      await _agoraEngine!.muteLocalAudioStream(mute);
      print('Audio ${mute ? 'muted' : 'unmuted'}');
    } catch (e) {
      print('Error toggling audio: $e');
      _addError('Error toggling audio: $e');
    }
  }

  Future<void> toggleVideoMute(bool mute) async {
    try {
      await _agoraEngine!.muteLocalVideoStream(mute);
      await _agoraEngine!.enableLocalVideo(!mute);
      print('Video ${mute ? 'muted' : 'unmuted'}');
    } catch (e) {
      print('Error toggling video: $e');
      _addError('Error toggling video: $e');
    }
  }

  Future<void> switchCamera() async {
    try {
      await _agoraEngine!.switchCamera();
      print('Camera switched');
    } catch (e) {
      print('Error switching camera: $e');
      _addError('Error switching camera: $e');
    }
  }

  Future<void> dispose() async {
    try {
      print('Disposing Agora service...');
      await leaveChannel();
      await _agoraEngine?.stopPreview();
      await _agoraEngine?.release();
      _isInitialized = false;
      _isJoined = false;
      _isScreenSharing = false;
      print('Agora service disposed');
    } catch (e) {
      print('Error disposing Agora: $e');
      _addError('Error disposing Agora: $e');
    }
  }

  void _addError(String error) {
    print('Adding error to BLoC: $error');
    _videoCallBloc?.add(ErrorOccurredEvent(error));
  }

  bool get isAndroid => true;

  RtcEngine? get engine => _agoraEngine;

  bool get isInitialized => _isInitialized;

  bool get isJoined => _isJoined;

  bool get isScreenSharing => _isScreenSharing;
}
