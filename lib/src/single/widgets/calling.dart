import 'package:flutter/material.dart';
import 'package:flutter_openim_live/flutter_openim_live.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../client.dart';
import '../../widgets/avatar.dart';
import 'small_window.dart';

class CallingView extends StatelessWidget {
  const CallingView({
    Key? key,
    required this.initState,
    required this.state,
    required this.type,
    required this.nickname,
    this.faceURL,
    this.isMinimize = false,
    this.callingDuration,
    this.onTapMaximizeBtn,
  }) : super(key: key);
  final CallState state;
  final CallState initState;
  final CallType type;
  final bool isMinimize;
  final String? callingDuration;
  final String nickname;
  final String? faceURL;
  final Function()? onTapMaximizeBtn;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedScale(
          scale: isMinimize ? 0 : 1,
          alignment: const Alignment(0.9, -0.8),
          duration: const Duration(milliseconds: 200),
          child: SizedBox(
            width: 1.sw,
            child: Stack(
              alignment: Alignment.center,
              children: _children(),
            ),
          ),
        ),
        Positioned(
          top: 48.h,
          right: 13.w,
          child: SmallWindowView(
            state: state,
            opacity: isMinimize ? 1 : 0,
            onTapMaximize: onTapMaximizeBtn,
          ),
        ),
      ],
    );
  }

  /// 通话中
  bool get _isCalling => state == CallState.calling;

  /// 拨打
  bool get _isDail => state == CallState.call;

  /// 收到邀请
  bool get _isBeCalled => state == CallState.beCalled;

  bool get _isAudio => type == CallType.audio;

  List<Widget> _children() => _isAudio
      ? [
          Positioned(
            top: 70.h,
            child: Avatar(url: faceURL),
          ),
          Positioned(
            top: 140.h,
            child: _buildNameText(),
          ),
          Positioned(
            top: 200.h,
            child: _buildStatusText(),
          )
        ]
      : [
          if (state == CallState.calling)
            Positioned(
              top: 20.h,
              child: _buildVideoCallDurationText(),
            ),
          if (state != CallState.calling)
            Positioned(
              top: 119.h,
              left: 30.w,
              width: 1.sw,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Avatar(url: faceURL),
                  SizedBox(width: 24.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNameText(),
                      _buildStatusText(),
                    ],
                  ),
                ],
              ),
            ),
        ];

  // (_isBeCalled ? '邀请你进行语音通话…' : callingDuration ?? '00:00'),
  Widget _buildStatusText() => _isAudio
      ? Text(
          initState == CallState.call
              ? (state != CallState.calling
                  ? '正在等待对方接听…'
                  : callingDuration ?? '00:00')
              : (state != CallState.calling
                  ? '邀请你进行语音通话…'
                  : callingDuration ?? '00:00'),
          style: TextStyle(
              fontSize: 18.sp,
              color: const Color(
                0xFFFFFFFF,
              )),
        )
      : Text(
          initState == CallState.call
              ? (state != CallState.calling
                  ? '正在等待对方接受邀请'
                  : callingDuration ?? '00:00')
              : (state != CallState.calling
                  ? '邀请你进行视频通话…'
                  : callingDuration ?? '00:00'),
          style: TextStyle(
              fontSize: 14.sp,
              color: const Color(
                0xFFFFFFFF,
              )),
        );

  Widget _buildNameText() => Text(
        nickname,
        style: TextStyle(
            fontSize: _isAudio ? 24.sp : 32.sp,
            color: const Color(
              0xFFFFFFFF,
            )),
      );

  Widget _buildVideoCallDurationText() => Text(
        callingDuration ?? '00:00',
        style: TextStyle(
            fontSize: 18.sp,
            color: const Color(
              0xFFFFFFFF,
            )),
      );
}

/*

class CallingView extends StatelessWidget {
  const CallingView({
    Key? key,
    required this.state,
    required this.type,
    required this.nickname,
    this.url,
    this.micOpen = true,
    this.speakerOpen = true,
    this.isMinimize = false,
    this.callingDuration,
    this.onTapCancelBtn,
    this.onTapHangupBtn,
    this.onTapMicBtn,
    this.onTapPickupBtn,
    this.onTapRejectBtn,
    this.onTapSpeakerBtn,
    this.onTapMinimizeBtn,
    this.onTapMaximizeBtn,
    this.onTapTurnCameraBtn,
  }) : super(key: key);
  final CallState state;
  final CallType type;
  final bool micOpen;
  final bool speakerOpen;
  final bool isMinimize;
  final String? callingDuration;
  final String nickname;
  final String? url;
  final Function()? onTapMicBtn;
  final Function()? onTapSpeakerBtn;
  final Function()? onTapHangupBtn;
  final Function()? onTapCancelBtn;
  final Function()? onTapRejectBtn;
  final Function()? onTapPickupBtn;
  final Function()? onTapMinimizeBtn;
  final Function()? onTapMaximizeBtn;
  final Function()? onTapTurnCameraBtn;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedScale(
          scale: isMinimize ? 0 : 1,
          alignment: const Alignment(0.9, -0.8),
          duration: const Duration(milliseconds: 200),
          child: Container(
            color: const Color(0xFF262626),
            child: type == CallType.audio
                ? AudioCallingView(
                    state: state,
                    nickname: nickname,
                    url: url,
                    micOpen: micOpen,
                    speakerOpen: speakerOpen,
                    callingDuration: callingDuration,
                    onTapSpeakerBtn: onTapSpeakerBtn,
                    onTapRejectBtn: onTapRejectBtn,
                    onTapPickupBtn: onTapPickupBtn,
                    onTapMinimizeBtn: onTapMinimizeBtn,
                    onTapMicBtn: onTapMicBtn,
                    onTapHangupBtn: onTapHangupBtn,
                    onTapCancelBtn: onTapCancelBtn,
                  )
                : VideoCallingView(
                    state: state,
                    nickname: nickname,
                    url: url,
                    micOpen: micOpen,
                    speakerOpen: speakerOpen,
                    callingDuration: callingDuration,
                    onTapSpeakerBtn: onTapSpeakerBtn,
                    onTapRejectBtn: onTapRejectBtn,
                    onTapPickupBtn: onTapPickupBtn,
                    onTapMinimizeBtn: onTapMinimizeBtn,
                    onTapMicBtn: onTapMicBtn,
                    onTapHangupBtn: onTapHangupBtn,
                    onTapCancelBtn: onTapCancelBtn,
                    onTapTurnCameraBtn: onTapTurnCameraBtn,
                  ),
          ),
        ),
        Positioned(
          top: 48.h,
          right: 13.w,
          child: SmallWindowView(
            state: state,
            opacity: isMinimize ? 1 : 0,
            onTapMaximize: onTapMaximizeBtn,
          ),
        ),
      ],
    );
  }
}

class AudioCallingView extends StatelessWidget {
  const AudioCallingView({
    Key? key,
    required this.state,
    this.micOpen = true,
    this.speakerOpen = true,
    this.callingDuration,
    required this.nickname,
    this.url,
    this.onTapCancelBtn,
    this.onTapHangupBtn,
    this.onTapMicBtn,
    this.onTapPickupBtn,
    this.onTapRejectBtn,
    this.onTapSpeakerBtn,
    this.onTapMinimizeBtn,
  }) : super(key: key);
  final CallState state;
  final bool micOpen;
  final bool speakerOpen;
  final String? callingDuration;
  final String nickname;
  final String? url;
  final Function()? onTapMicBtn;
  final Function()? onTapSpeakerBtn;
  final Function()? onTapHangupBtn;
  final Function()? onTapCancelBtn;
  final Function()? onTapRejectBtn;
  final Function()? onTapPickupBtn;
  final Function()? onTapMinimizeBtn;

  /// 通话中
  bool get _isCalling => state == CallState.calling;

  /// 拨打
  bool get _isDail => state == CallState.call;

  /// 收到邀请
  bool get _isBeCalled => state == CallState.beCalled;

  List<Widget> _buildButtons() => _isDail || _isCalling
      ? [
          Button.mic(
            open: micOpen,
            onTap: onTapMicBtn,
          ),
          Button.hangUp(
            type: _isCalling ? 3 : 1,
            onTap: _isCalling ? onTapHangupBtn : onTapCancelBtn,
          ),
          Button.speaker(
            open: speakerOpen,
            onTap: onTapSpeakerBtn,
          ),
        ]
      : [
          Button.hangUp(
            type: 2,
            onTap: onTapRejectBtn,
          ),
          Button.pickUp(
            onTap: onTapPickupBtn,
          ),
        ];

  Widget _buildStatusText() => Text(
        _isDail
            ? '正在等待对方接听…'
            : (_isBeCalled ? '邀请你进行语音通话…' : callingDuration ?? '00:00'),
        style: TextStyle(
            fontSize: 18.sp,
            color: const Color(
              0xFFFFFFFF,
            )),
      );

  Widget _buildNameText() => Text(
        nickname,
        style: TextStyle(
            fontSize: 24.sp,
            color: const Color(
              0xFFFFFFFF,
            )),
      );

  Widget _buildMinimizeButton() => GestureDetector(
        onTap: onTapMinimizeBtn,
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 22.w,
          top: 48.h,
          child: _buildMinimizeButton(),
        ),
        Positioned(
          top: 159.h,
          child: Avatar(url: url),
        ),
        Positioned(
          top: 252.h,
          child: _buildNameText(),
        ),
        Positioned(
          top: 314.h,
          child: _buildStatusText(),
        ),
        Positioned(
          bottom: 68.h,
          width: 1.sw,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _buildButtons(),
          ),
        ),
      ],
    );
  }
}

class VideoCallingView extends StatelessWidget {
  const VideoCallingView({
    Key? key,
    required this.state,
    this.micOpen = true,
    this.speakerOpen = true,
    this.callingDuration,
    required this.nickname,
    this.url,
    this.onTapCancelBtn,
    this.onTapHangupBtn,
    this.onTapMicBtn,
    this.onTapPickupBtn,
    this.onTapRejectBtn,
    this.onTapSpeakerBtn,
    this.onTapMinimizeBtn,
    this.onTapTurnCameraBtn,
  }) : super(key: key);
  final CallState state;
  final bool micOpen;
  final bool speakerOpen;
  final String? callingDuration;
  final String nickname;
  final String? url;
  final Function()? onTapMicBtn;
  final Function()? onTapSpeakerBtn;
  final Function()? onTapHangupBtn;
  final Function()? onTapCancelBtn;
  final Function()? onTapRejectBtn;
  final Function()? onTapPickupBtn;
  final Function()? onTapMinimizeBtn;
  final Function()? onTapTurnCameraBtn;

  /// 通话中
  bool get _isCalling => state == CallState.calling;

  /// 拨打
  bool get _isDail => state == CallState.call;

  /// 收到邀请
  bool get _isBeCalled => state == CallState.beCalled;

  List<Widget> _buildButtons() => _isDail || _isCalling
      ? [
          Button.mic(
            open: micOpen,
            onTap: onTapMicBtn,
          ),
          Button.hangUp(
            type: _isCalling ? 3 : 1,
            onTap: _isCalling ? onTapHangupBtn : onTapCancelBtn,
          ),
          Button.speaker(
            open: speakerOpen,
            onTap: onTapSpeakerBtn,
          ),
        ]
      : [
          Button.hangUp(
            type: 2,
            onTap: onTapRejectBtn,
          ),
          Button.pickUp(
            onTap: onTapPickupBtn,
          ),
        ];

  Widget _buildStatusText() => Text(
        _isDail
            ? '正在等待对方接受邀请'
            : (_isBeCalled ? '邀请你进行视频通话…' : callingDuration ?? '00:00'),
        style: TextStyle(
            fontSize: 14.sp,
            color: const Color(
              0xFFFFFFFF,
            )),
      );

  Widget _buildVideoCallDurationText() => Text(
        callingDuration ?? '00:00',
        style: TextStyle(
            fontSize: 18.sp,
            color: const Color(
              0xFFFFFFFF,
            )),
      );

  Widget _buildNameText() => Text(
        nickname,
        style: TextStyle(
            fontSize: 32.sp,
            color: const Color(
              0xFFFFFFFF,
            )),
      );

  Widget _buildMinimizeButton() => GestureDetector(
        onTap: onTapMinimizeBtn,
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

  Widget _buildTurnCameraButton() => GestureDetector(
        onTap: onTapTurnCameraBtn,
        child: SizedBox(
          width: 36.w,
          height: 36.h,
          child: Center(
            child: Image.asset(
              'assets/images/turn_camera.webp',
              package: 'flutter_openim_live',
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 22.w,
          top: 48.h,
          child: _buildMinimizeButton(),
        ),
        if (state != CallState.beCalled)
          Positioned(
            right: 22.w,
            top: 48.h,
            child: _buildTurnCameraButton(),
          ),
        if (state == CallState.calling)
          Positioned(
            top: 54.h,
            child: _buildVideoCallDurationText(),
          ),
        if (state != CallState.calling)
          Positioned(
            top: 119.h,
            left: 30.w,
            width: 1.sw,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Avatar(url: url),
                SizedBox(width: 24.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNameText(),
                    _buildStatusText(),
                  ],
                ),
              ],
            ),
          ),
        Positioned(
          bottom: 68.h,
          width: 1.sw,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _buildButtons(),
          ),
        ),
      ],
    );
  }
}
*/
