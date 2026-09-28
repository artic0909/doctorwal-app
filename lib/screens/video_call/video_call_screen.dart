import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:demoapp/Services/apiservice.dart';

class VideoCallScreen extends StatefulWidget {
  final String appId;
  final String channelName;
  final String token;
  final int uid;
  final int appointmentId;
  final String participantName;
  final String role; // 'patient' or 'doctor'

  const VideoCallScreen({
    super.key,
    required this.appId,
    required this.channelName,
    required this.token,
    required this.uid,
    required this.appointmentId,
    required this.participantName,
    this.role = 'patient',
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late RtcEngine _engine;
  final ApiService _apiService = ApiService();

  int? _remoteUid;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isSpeakerOn = true;
  bool _isFrontCamera = true;
  bool _isReconnecting = false;
  bool _isRemoteVideoMuted = false;
  bool _isRemoteAudioMuted = false;
  String _networkQualityText = 'Good';
  Color _networkQualityColor = Colors.green;
  bool _isWeakNetworkAudioFallback = false;

  late String _currentToken;
  Timer? _callTimer;
  int _callDurationSeconds = 0;

  // Local PIP draggable offset
  Offset _localPipOffset = const Offset(20, 80);

  @override
  void initState() {
    super.initState();
    _currentToken = widget.token;
    _initAgora();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _disposeEngine();
    super.dispose();
  }

  Future<void> _disposeEngine() async {
    try {
      await WakelockPlus.disable();
    } catch (_) {}
    try {
      await _engine.leaveChannel();
      await _engine.release();
    } catch (_) {}
  }

  Future<void> _initAgora() async {
    // 1. Request Camera & Mic Permissions
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      if (!mounted) return;
      _showPermissionDeniedDialog();
      return;
    }

    try {
      await WakelockPlus.enable();
    } catch (_) {}

    try {
      // 2. Initialize RtcEngine
      _engine = createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(
        appId: widget.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // 3. Register Callbacks
      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            if (!mounted) return;
            setState(() {
              _isJoined = true;
              _isReconnecting = false;
            });
            _startCallTimer();
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            if (!mounted) return;
            setState(() {
              _remoteUid = remoteUid;
              _isRemoteVideoMuted = false;
            });
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            if (!mounted) return;
            setState(() {
              if (_remoteUid == remoteUid) {
                _remoteUid = null;
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Participant left the video consultation.'),
                duration: Duration(seconds: 3),
              ),
            );
          },
          onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
            _renewToken();
          },
          onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
            if (!mounted) return;
            if (state == ConnectionStateType.connectionStateReconnecting) {
              setState(() => _isReconnecting = true);
            } else if (state == ConnectionStateType.connectionStateConnected) {
              setState(() => _isReconnecting = false);
            } else if (state == ConnectionStateType.connectionStateFailed) {
              setState(() => _isReconnecting = false);
              _showErrorDialog("Connection lost. Please check your internet connection.");
            }
          },
          onNetworkQuality: (RtcConnection connection, int uid, QualityType txQuality, QualityType rxQuality) {
            if (!mounted) return;
            _handleNetworkQuality(rxQuality);
          },
          onUserMuteVideo: (RtcConnection connection, int remoteUid, bool muted) {
            if (!mounted) return;
            if (_remoteUid == remoteUid) {
              setState(() => _isRemoteVideoMuted = muted);
            }
          },
          onUserMuteAudio: (RtcConnection connection, int remoteUid, bool muted) {
            if (!mounted) return;
            if (_remoteUid == remoteUid) {
              setState(() => _isRemoteAudioMuted = muted);
            }
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint("Agora Error [$err]: $msg");
          },
        ),
      );

      // 4. Setup Media
      await _engine.enableVideo();
      await _engine.startPreview();
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine.setEnableSpeakerphone(_isSpeakerOn);

      // 5. Join Channel
      await _engine.joinChannel(
        token: _currentToken,
        channelId: widget.channelName,
        uid: widget.uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );

      // Update backend status to live
      _apiService.updateVideoStatus(widget.appointmentId, 'live');

    } catch (e) {
      if (mounted) {
        _showErrorDialog("Failed to initialize video call: $e");
      }
    }
  }

  void _startCallTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDurationSeconds++;
        });
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _handleNetworkQuality(QualityType quality) {
    if (quality == QualityType.qualityExcellent || quality == QualityType.qualityGood) {
      setState(() {
        _networkQualityText = 'HD';
        _networkQualityColor = Colors.green;
        _isWeakNetworkAudioFallback = false;
      });
    } else if (quality == QualityType.qualityPoor) {
      setState(() {
        _networkQualityText = 'Fair';
        _networkQualityColor = Colors.orange;
      });
    } else if (quality == QualityType.qualityBad || quality == QualityType.qualityVbad) {
      setState(() {
        _networkQualityText = 'Poor';
        _networkQualityColor = Colors.red;
      });
      // Suggest or toggle audio-only fallback on very bad network
      if (!_isWeakNetworkAudioFallback) {
        _isWeakNetworkAudioFallback = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Weak network detected. Video quality adjusted for stability.'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _renewToken() async {
    try {
      final response = await _apiService.getVideoCallToken(widget.appointmentId);
      if (response['status'] == true && response['data']?['token'] != null) {
        final newToken = response['data']['token'];
        _currentToken = newToken;
        await _engine.renewToken(newToken);
      }
    } catch (_) {}
  }

  void _toggleMute() async {
    setState(() => _isMuted = !_isMuted);
    await _engine.muteLocalAudioStream(_isMuted);
  }

  void _toggleVideo() async {
    setState(() => _isVideoOff = !_isVideoOff);
    await _engine.muteLocalVideoStream(_isVideoOff);
  }

  void _switchCamera() async {
    setState(() => _isFrontCamera = !_isFrontCamera);
    await _engine.switchCamera();
  }

  void _toggleSpeaker() async {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    await _engine.setEnableSpeakerphone(_isSpeakerOn);
  }

  Future<void> _endCall() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('End Consultation', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to end this video call?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End Call'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _disposeEngine();
      try {
        await _apiService.updateVideoStatus(widget.appointmentId, 'completed');
      } catch (_) {}
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Permissions Required'),
        content: const Text(
          'Doctorwala needs Camera and Microphone permissions to connect your video consultation with the doctor.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final nav = Navigator.of(this.context);
              await openAppSettings();
              if (mounted) nav.pop();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Video Error'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            // 1. Remote Fullscreen Video or Waiting Screen
            Positioned.fill(
              child: _buildRemoteVideoView(),
            ),

            // 2. Top Bar (Participant info, duration, network badge)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: _buildTopHeader(),
            ),

            // 3. Reconnecting Banner
            if (_isReconnecting)
              Positioned(
                top: MediaQuery.of(context).padding.top + 70,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Reconnecting to video session...',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

            // 4. Draggable Local PIP Video Preview
            if (_isJoined)
              Positioned(
                left: _localPipOffset.dx,
                top: _localPipOffset.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _localPipOffset = Offset(
                        (_localPipOffset.dx + details.delta.dx).clamp(10.0, screenSize.width - 130),
                        (_localPipOffset.dy + details.delta.dy).clamp(60.0, screenSize.height - 220),
                      );
                    });
                  },
                  child: _buildLocalPipPreview(),
                ),
              ),

            // 5. Bottom Control Bar
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: _buildControlBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF1B9AAA),
            child: Text(
              widget.participantName.isNotEmpty ? widget.participantName[0].toUpperCase() : 'D',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.participantName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _remoteUid != null ? Colors.green : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _remoteUid != null ? _formatDuration(_callDurationSeconds) : 'Connecting...',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Network Quality Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _networkQualityColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _networkQualityColor.withValues(alpha: 0.6)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi, color: _networkQualityColor, size: 14),
                const SizedBox(width: 4),
                Text(
                  _networkQualityText,
                  style: TextStyle(color: _networkQualityColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoteVideoView() {
    if (_remoteUid != null) {
      if (_isRemoteVideoMuted) {
        return Container(
          color: const Color(0xFF111827),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFF1B9AAA).withValues(alpha: 0.3),
                  child: Text(
                    widget.participantName.isNotEmpty ? widget.participantName[0].toUpperCase() : 'D',
                    style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.participantName,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Camera is turned off',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (_isRemoteAudioMuted)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mic_off, size: 14, color: Colors.redAccent),
                        SizedBox(width: 4),
                        Text('Muted', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      }

      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    }

    // Waiting for other participant to join
    return Container(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF1B9AAA).withValues(alpha: 0.2),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF1B9AAA)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Waiting for ${widget.participantName} to join...",
              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Doctorwala Video Room: ${widget.channelName}",
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalPipPreview() {
    return Container(
      width: 110,
      height: 155,
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: _isVideoOff
            ? Container(
                color: const Color(0xFF1F2937),
                child: const Center(
                  child: Icon(Icons.videocam_off, color: Colors.white54, size: 28),
                ),
              )
            : AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _engine,
                  canvas: const VideoCanvas(uid: 0),
                ),
              ),
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute Mic
          _controlCircleButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            isActive: !_isMuted,
            activeColor: Colors.white.withValues(alpha: 0.2),
            inactiveColor: Colors.redAccent,
            onTap: _toggleMute,
          ),

          // Camera On/Off
          _controlCircleButton(
            icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
            isActive: !_isVideoOff,
            activeColor: Colors.white.withValues(alpha: 0.2),
            inactiveColor: Colors.redAccent,
            onTap: _toggleVideo,
          ),

          // Flip Camera
          _controlCircleButton(
            icon: Icons.flip_camera_ios_rounded,
            isActive: true,
            activeColor: Colors.white.withValues(alpha: 0.2),
            inactiveColor: Colors.white.withValues(alpha: 0.2),
            onTap: _switchCamera,
          ),

          // Speaker Toggle
          _controlCircleButton(
            icon: _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
            isActive: _isSpeakerOn,
            activeColor: Colors.white.withValues(alpha: 0.2),
            inactiveColor: Colors.white.withValues(alpha: 0.2),
            onTap: _toggleSpeaker,
          ),

          // End Call Button
          InkWell(
            onTap: _endCall,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call_end, color: Colors.white, size: 26),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlCircleButton({
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: isActive ? activeColor : inactiveColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
