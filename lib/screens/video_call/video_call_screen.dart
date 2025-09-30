import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_calling_app/widgets/error_widget.dart';

import '../../../data/services/agora_service.dart';
import '../../../utils/constants.dart';
import '../../../widgets/loading_indicator.dart';
import '../../bloc/video_call/video_call_bloc.dart';
import '../../utils/app_colors.dart';

class VideoCallScreen extends StatefulWidget {
  final String? channelName;

  const VideoCallScreen({super.key, this.channelName});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCall();
    });
  }

  void _initializeCall() {
    final channelName = widget.channelName ?? AppConstants.defaultChannelName;
    context.read<VideoCallBloc>().add(
      InitializeVideoCallEvent(channelName: channelName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VideoCallBloc, VideoCallState>(
      listener: (context, state) {
        print(' BLoC State Changed: ${state.status}');

        if (state.status == VideoCallStatus.connected) {
          print(' CONNECTED! Local UID: ${state.localUid}');
          print(' Remote UIDs: ${state.remoteUids}');
        }

        if (state.status == VideoCallStatus.disconnected) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.videoCallBackground,
        body: BlocBuilder<VideoCallBloc, VideoCallState>(
          buildWhen: (previous, current) {
            return previous.status != current.status ||
                previous.remoteUids != current.remoteUids ||
                previous.isScreenSharing != current.isScreenSharing;
          },
          builder: (context, state) {
            return Stack(
              children: [
                _buildMainContent(context, state),

                if (state.isInCall) _buildCallControls(context, state),

            //    _buildDebugOverlay(state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, VideoCallState state) {
    switch (state.status) {
      case VideoCallStatus.initial:
        return _buildInitialView();

      case VideoCallStatus.loading:
        return const LoadingIndicator(message: 'Initializing...');

      case VideoCallStatus.checkingPermissions:
        return const LoadingIndicator(message: 'Checking permissions...');

      case VideoCallStatus.permissionsDenied:
        return _buildPermissionsDeniedView(context);

      case VideoCallStatus.initializingAgora:
        return const LoadingIndicator(message: 'Initializing video...');

      case VideoCallStatus.joiningChannel:
        return const LoadingIndicator(message: 'Joining channel...');

      case VideoCallStatus.connected:
      case VideoCallStatus.screenSharing:
        return _buildVideoCallView(context, state);

      case VideoCallStatus.disconnecting:
        return const LoadingIndicator(message: 'Leaving call...');

      case VideoCallStatus.disconnected:
        return _buildDisconnectedView();

      case VideoCallStatus.error:
        return CustomErrorWidget(
          message: state.error ?? 'An error occurred',
          onRetry: () => _initializeCall(),
        );

      default:
        return const LoadingIndicator();
    }
  }

  Widget _buildInitialView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(
            'Preparing video call...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.call_end, size: 80, color: Colors.white),
          const SizedBox(height: 20),
          const Text(
            'Call ended',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _initializeCall(),
            child: const Text('Start New Call'),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCallView(BuildContext context, VideoCallState state) {
    final agoraService = context.read<AgoraService>();

    return Stack(
      children: [
        _buildVideoViews(context, state, agoraService),

        _buildHeaderInfo(state),

        if (state.isScreenSharing) _buildScreenShareIndicator(),
      ],
    );
  }

  Widget _buildVideoViews(
    BuildContext context,
    VideoCallState state,
    AgoraService agoraService,
  ) {
    final hasScreenShare = state.screenShareUid != null;
    final hasRemoteUsers = state.remoteUids.isNotEmpty;

    return Stack(
      children: [
        if (hasScreenShare && agoraService.engine != null)
          AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: agoraService.engine!,
              canvas: VideoCanvas(uid: state.screenShareUid),
              connection: RtcConnection(
                channelId: state.channelName ?? AppConstants.defaultChannelName,
              ),
            ),
          ),

        if (hasRemoteUsers && agoraService.engine != null && !hasScreenShare)
          _buildRemoteUsersView(state, agoraService),

        if (!hasRemoteUsers && !hasScreenShare)
          _buildWaitingView(state, agoraService),

        if (agoraService.engine != null && !state.isScreenSharing)
          _buildLocalVideoPreview(agoraService),
      ],
    );
  }

  Widget _buildWaitingView(VideoCallState state, AgoraService agoraService) {
    return Container(
      color: AppColors.backgroundDark,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_search, size: 80, color: Colors.white54),
            const SizedBox(height: 20),
            const Text(
              'Waiting for participants...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Channel: ${state.channelName ?? AppConstants.defaultChannelName}',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 20),
            if (state.localUid != null)
              Text(
                'Your UID: ${state.localUid}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteUsersView(
    VideoCallState state,
    AgoraService agoraService,
  ) {
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: agoraService.engine!,
        canvas: VideoCanvas(uid: state.remoteUids.first),
        connection: RtcConnection(
          channelId: state.channelName ?? AppConstants.defaultChannelName,
        ),
      ),
    );
  }

  Widget _buildLocalVideoPreview(AgoraService agoraService) {
    return Positioned(
      top: 60,
      right: 20,
      width: 120,
      height: 180,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: agoraService.engine!,
              canvas: const VideoCanvas(uid: 0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(VideoCallState state) {
    return Positioned(
      top: 40,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [

            const SizedBox(width: 16),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: state.isInCall ? Colors.green : Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              state.isInCall ? 'Live' : 'Connecting',
              style: TextStyle(
                color: state.isInCall ? Colors.green : Colors.orange,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            if (state.localUid != null)
              Text(
                'Your UID: ${state.localUid}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugOverlay(VideoCallState state) {
    return Positioned(
      bottom: 150,
      left: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: ${state.status}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              'Local UID: ${state.localUid ?? "N/A"}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              'Remote UIDs: ${state.remoteUids}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenShareIndicator() {
    return Positioned(
      top: 100,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.screen_share, color: Colors.white, size: 14),
            SizedBox(width: 6),
            Text(
              'Sharing Screen',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallControls(BuildContext context, VideoCallState state) {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildControlButton(
              icon: state.isAudioMuted ? Icons.mic_off : Icons.mic,
              backgroundColor: state.isAudioMuted
                  ? AppColors.videoCallMuted
                  : AppColors.primary,
              onPressed: () =>
                  context.read<VideoCallBloc>().add(ToggleAudioEvent()),
              label: state.isAudioMuted ? 'Unmute' : 'Mute',
            ),

            // Mute Video
            _buildControlButton(
              icon: state.isVideoMuted ? Icons.videocam_off : Icons.videocam,
              backgroundColor: state.isVideoMuted
                  ? AppColors.videoCallMuted
                  : AppColors.primary,
              onPressed: () =>
                  context.read<VideoCallBloc>().add(ToggleVideoEvent()),
              label: state.isVideoMuted ? 'Enable Video' : 'Disable Video',
            ),

            _buildControlButton(
              icon: state.isScreenSharing
                  ? Icons.stop_screen_share
                  : Icons.screen_share,
              backgroundColor: state.isScreenSharing
                  ? AppColors.videoCallMuted
                  : AppColors.primary,
              onPressed: state.isScreenSharing
                  ? () => context.read<VideoCallBloc>().add(
                      StopScreenShareEvent(),
                    )
                  : () => context.read<VideoCallBloc>().add(
                      StartScreenShareEvent(),
                    ),
              label: state.isScreenSharing ? 'Stop Share' : 'Share Screen',
            ),

            _buildControlButton(
              icon: Icons.call_end,
              backgroundColor: AppColors.error,
              onPressed: () =>
                  context.read<VideoCallBloc>().add(LeaveChannelEvent()),
              label: 'End Call',
              isEndCall: true,
            ),

            _buildControlButton(
              icon: Icons.switch_camera,
              backgroundColor: AppColors.primary,
              onPressed: () =>
                  context.read<VideoCallBloc>().add(SwitchCameraEvent()),
              label: 'Switch Camera',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
    required String label,
    bool isEndCall = false,
  }) {
    return Column(
      children: [
        Container(
          width: isEndCall ? 60 : 50,
          height: isEndCall ? 60 : 50,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: isEndCall ? 24 : 20),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildPermissionsDeniedView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              'Permissions Required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This app needs camera and microphone permissions to make video calls.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    context.read<VideoCallBloc>().add(
                      RequestPermissionsEvent(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Grant Permissions'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                print('Open app settings');
              },
              child: const Text(
                'Open Settings',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
