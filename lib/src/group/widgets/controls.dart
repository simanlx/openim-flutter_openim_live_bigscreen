import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_openim_live/flutter_openim_live.dart';
import 'package:flutter_openim_live/src/widgets/button.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';

class ControlsWidget extends StatefulWidget {
  final CallState state;
  final CallType type;
  final Widget child;
  final Future Function()? onReject;
  final Future Function()? onPickup;
  final Future Function()? onBack;
  final Future Function()? onHangup;
  final Function()? onMinimize;
  final PublishSubject<Room> roomSubject;
  final PublishSubject<CallState> stateSubject;

  const ControlsWidget({
    Key? key,
    required this.state,
    required this.type,
    required this.child,
    this.onReject,
    this.onPickup,
    this.onBack,
    this.onHangup,
    this.onMinimize,
    required this.roomSubject,
    required this.stateSubject,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ControlsWidgetState();
}

class _ControlsWidgetState extends State<ControlsWidget> {
  //
  CameraPosition position = CameraPosition.front;
  late CallState state;
  Room? room;
  LocalParticipant? participant;
  var speakerOpen = true;

  // Use this object to prevent concurrent access to data
  var lockVideo = Lock();
  var lockAudio = Lock();
  var lockCamera = Lock();

  @override
  void initState() {
    super.initState();
    state = widget.state;
    widget.roomSubject.listen((r) {
      room ??= r;
      if (r.localParticipant != null && participant == null) {
        participant = r.localParticipant;
        participant?.addListener(_onChange);
      }
    });
    widget.stateSubject.listen((e) {
      state = e;
      _onChange();
    });
  }

  @override
  void dispose() {
    participant?.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    // trigger refresh
    if (!mounted) return;
    setState(() {});
  }

  void _unpublishAll() async {
    await participant?.unpublishAllTracks();
  }

  _disableAudio() async {
    await participant?.setMicrophoneEnabled(false);
  }

  _enableAudio() async {
    await participant?.setMicrophoneEnabled(true);
  }

  _toggleAudio() async {
    if (participant == null) return;
    await lockAudio.synchronized(() async {
      if (participant?.isMicrophoneEnabled() == true) {
        await _disableAudio();
      } else {
        await _enableAudio();
      }
    });
  }

  _disableVideo() async {
    await participant?.setCameraEnabled(false);
  }

  _enableVideo() async {
    await participant?.setCameraEnabled(true);
  }

  _toggleVideo() async {
    if (participant == null) return;
    await lockVideo.synchronized(() async {
      if (participant?.isCameraEnabled() == true) {
        await _disableVideo();
      } else {
        await _enableVideo();
      }
    });
  }

  _toggleCamera() async {
    final track = participant?.videoTracks.firstOrNull?.track;
    if (track == null) return;
    //
    await lockCamera.synchronized(() async {
      try {
        final newPosition = position.switched();
        await track.setCameraPosition(newPosition);
        setState(() {
          position = newPosition;
        });
      } catch (error) {
        print('could not restart track: $error');
        return;
      }
    });
  }

  _enableScreenShare() async {
    await participant?.setScreenShareEnabled(true);

    if (Platform.isAndroid) {
      // Android specific
      try {
        // Required for android screenshare.
        const androidConfig = FlutterBackgroundAndroidConfig(
          notificationTitle: 'Screen Sharing',
          notificationText: 'LiveKit Example is sharing the screen.',
          notificationImportance: AndroidNotificationImportance.Default,
          notificationIcon:
              AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
        );
        await FlutterBackground.initialize(androidConfig: androidConfig);
        await FlutterBackground.enableBackgroundExecution();
      } catch (e) {
        print('could not publish video: $e');
      }
    }
  }

  void _disableScreenShare() async {
    await participant?.setScreenShareEnabled(false);
    if (Platform.isAndroid) {
      // Android specific
      try {
        //   await FlutterBackground.disableBackgroundExecution();
      } catch (error) {
        print('error disabling screen share: $error');
      }
    }
  }

  void _onTapDisconnect() async {
    await room?.disconnect();
  }

  void _onTapReconnect() async {
    try {
      await room?.reconnect();
    } catch (error) {}
  }

  void _onTapUpdateSubscribePermission() async {
    try {
      room?.localParticipant?.setTrackSubscriptionPermissions(
        allParticipantsAllowed: true,
      );
    } catch (error) {}
  }

  void _onTapSimulateScenario() async {
    // await widget.room.simulateScenario(
    //   nodeFailure: result == SimulateScenarioResult.nodeFailure ? true : null,
    //   migration: result == SimulateScenarioResult.migration ? true : null,
    //   serverLeave: result == SimulateScenarioResult.serverLeave ? true : null,
    // );
  }

  void _onTapSendData() async {
    await participant?.publishData(
      utf8.encode('This is a sample data message'),
    );
  }

  _onTapSpeaker() async {
    print('----------_onTapSpeaker-----------------');
    _enableSpeakerphone(!speakerOpen);
    speakerOpen = !speakerOpen;
    print('----------_onTapSpeaker-----$speakerOpen------------');
    setState(() {});
  }

  void _enableSpeakerphone(bool enabled) {
    LocalTrack? track;
    if (widget.type == CallType.video) {
      track = participant?.videoTracks.firstOrNull?.track;
    } else {
      track = participant?.audioTracks.firstOrNull?.track;
    }
    track?.mediaStreamTrack.enableSpeakerphone(enabled);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAppBar(),
        Expanded(child: widget.child),
        _buildButtons(),
      ],
    );
  }

  Widget _buildAppBar() => Container(
        margin: EdgeInsets.only(top: 57.h, left: 22.w, right: 22.w),
        height: 45.h,
        child: Row(
          children: [
            // SimpleButton.back(onTap: widget.onBack),
            _buildMinimizeButton(),
            const Spacer(),
            if (widget.type == CallType.video)
              SimpleButton.video(
                open: participant?.isCameraEnabled() != false,
                onTap: _toggleVideo,
              ),
          ],
        ),
      );

  Widget _buildButtons() => state == CallState.beCalled
      ? Container(
          margin: EdgeInsets.only(bottom: 69.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Button.hangUp(type: 2, onTap: widget.onReject),
              Button.pickUp(onTap: widget.onPickup),
            ],
          ),
        )
      : Container(
          margin: EdgeInsets.only(bottom: 39.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Button.mic(
                open: participant?.isMicrophoneEnabled() != false,
                onTap: () => _toggleAudio(),
              ),
              Button.hangUp(type: 3, onTap: widget.onHangup),
              widget.type == CallType.audio
                  ? Button.speaker(
                      onTap: () => _onTapSpeaker(),
                      open: speakerOpen,
                    )
                  : Button.turnCamera(onTap: () => _toggleCamera()),
            ],
          ),
        );

  Widget _buildMinimizeButton() => GestureDetector(
        onTap: widget.onMinimize,
        child: SizedBox(
          width: 36.w,
          height: 36.h,
          child: Center(
            child: Image.asset(
              'assets/images/minimize.webp',
              package: 'flutter_openim_live',
            ),
          ),
        ),
      );
}
