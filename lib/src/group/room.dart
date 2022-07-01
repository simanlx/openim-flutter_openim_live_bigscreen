import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_openim_live/src/group/widgets/calling.dart';
import 'package:flutter_openim_live/src/group/widgets/controls.dart';
import 'package:flutter_openim_live/src/utils.dart' as u;
import 'package:flutter_openim_live/src/widgets/no_video.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:rxdart/rxdart.dart';

import '../../flutter_openim_live.dart';
import '../single/widgets/participant.dart';
import '../single/widgets/small_window.dart';
import '../timer.dart';

class RoomPage extends StatefulWidget {
  const RoomPage({
    Key? key,
    required this.type,
    required this.eventChangedSubject,
    this.roomID,
    this.initState = CallState.call,
    this.simulcast = true,
    required this.inviterUserID,
    required this.inviteeUserIDList,
    required this.groupID,
    this.onTapCancel,
    this.onTapHangup,
    this.onTapReject,
    this.onTapPickup,
    this.onDisconnected,
    this.onClose,
    this.onDial,
    this.syncGroupInfo,
    this.syncGroupMemberInfo,
    this.onBindRoomID,
  }) : super(key: key);

  final CallType type;
  final CallState initState;
  final String? roomID;
  final bool simulcast;
  final String inviterUserID;
  final List<String> inviteeUserIDList;
  final String groupID;
  final PublishSubject<CallEvent> eventChangedSubject;
  final Future Function()? onDial;
  final Future Function()? onTapCancel;
  final Future Function(int duration, bool isPositive)? onTapHangup;
  final Future Function()? onTapPickup;
  final Future Function()? onTapReject;
  final Future Function(String groupID)? syncGroupInfo;
  final Future Function(String groupID, List<String> userIDList)?
      syncGroupMemberInfo;
  final Function()? onDisconnected;
  final Function()? onClose;
  final Function(String roomID)? onBindRoomID;

  @override
  _RoomPageState createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  final roomSubject = PublishSubject<Room>();
  final stateSubject = PublishSubject<CallState>();
  EventsListener<RoomEvent>? _listener;
  Room? _room;
  late CallState _state;
  var _duration = 0;
  Timer? _callingTimer;

  List<Map>? _memberInfoList;
  Map? _groupInfo;
  var _minimize = false;
  String? _roomID;
  StreamSubscription? _subs;

  @override
  void initState() {
    _state = widget.initState;
    _subs = widget.eventChangedSubject.stream
        .where((event) => u.Utils.isSameRoom(event, widget.roomID ?? _roomID))
        .listen(_onStateDidUpdate);
    widget.syncGroupInfo?.call(widget.groupID).then(_updateGroupInfo);
    widget.syncGroupMemberInfo?.call(
      widget.groupID,
      [widget.inviterUserID, ...widget.inviteeUserIDList],
    ).then(_updateMemberInfo);
    if (_state == CallState.call) _onDail();
    super.initState();
  }

  @override
  void dispose() {
    // always dispose listener
    (() async {
      _subs?.cancel();
      roomSubject.close();
      stateSubject.close();
      _callingTimer?.cancel();
      _room?.removeListener(_onRoomDidUpdate);
      await _listener?.dispose();
      await _room?.disconnect();
      await _room?.dispose();
    })();
    super.dispose();
  }

  _updateGroupInfo(value) {
    if (!mounted) return;
    setState(() {
      _groupInfo = value;
    });
  }

  _updateMemberInfo(value) {
    if (!mounted) return;
    setState(() {
      _memberInfoList = value;
    });
  }

  void _onDail() async {
    setState(() {
      _state = CallState.connecting;
    });
    var certificate = await widget.onDial!.call();
    widget.onBindRoomID?.call(_roomID = certificate["roomID"]);
    _connect(certificate['liveURL'], certificate['token']);
  }

  _connect(String url, String token) async {
    // Try to connect to a room
    // This will throw an Exception if it fails for any reason.
    print('------live-------start connect: $url   $token');
    _room = await LiveKitClient.connect(
      url,
      token,
      roomOptions: RoomOptions(
        defaultVideoPublishOptions: VideoPublishOptions(
          simulcast: widget.simulcast,
        ),
      ),
    );
    print('------live-------connect success-----');
    _listener = _room?.createListener();
    _room?.addListener(_onRoomDidUpdate);
    if (null != _listener) _setUpListeners();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _publish());
  }

  void _setUpListeners() => _listener!
    ..on<RoomDisconnectedEvent>((_) async {
      WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
        widget.onDisconnected?.call();
        _close();
      });
    })
    ..on<ParticipantConnectedEvent>((event) {})
    ..on<ParticipantDisconnectedEvent>((event) {})
    ..on<DataReceivedEvent>((event) {
      String decoded = 'Failed to decode';
      try {
        decoded = utf8.decode(event.data);
      } catch (_) {
        print('Failed to decode: $_');
      }
    });

  void _publish() async {
    // video will fail when running in ios simulator
    if (widget.type == CallType.video) {
      try {
        await _room?.localParticipant?.setCameraEnabled(true);
      } catch (error) {
        print('could not publish video: $error');
      }
      try {
        await _room?.localParticipant?.setMicrophoneEnabled(true);
      } catch (error) {
        print('could not publish audio: $error');
      }
    } else {
      try {
        await _room?.localParticipant?.setMicrophoneEnabled(true);
      } catch (error) {
        print('could not publish audio: $error');
      }
    }
    _startCalling();
  }

  void _onRoomDidUpdate() {
    if (!mounted) return;
    roomSubject.add(_room!);
    setState(() {});
    // _sortParticipants();
  }

  void _startCalling() {
    print('----------------_startCalling--------------');
    _state = CallState.calling;
    stateSubject.add(_state);
    _startCallingTimer();
  }

  void _startCallingTimer() {
    print('----------------_startCallingTimer--------------');
    _callingTimer ??= Timer.periodic(
      const Duration(seconds: 1),
      (timer, count) {
        if (!mounted) return;
        setState(() {
          _duration = count;
        });
      },
    );
  }

  void _onStateDidUpdate(CallEvent event) {
    print('CallEvent----------状态更新--------------');
    if (!mounted) return;
    stateSubject.add(_state = event.state);
    setState(() {});
    switch (_state) {
      // case CallState.call:
      //   break;
      // case CallState.beCalled:
      //   break;
      // case CallState.reject:
      //   break;
      // case CallState.cancel:
      //   break;
      // case CallState.hangup:
      //   break;
      // case CallState.beRejected:
      case CallState.beCanceled:
        // case CallState.beHangup:
        // case CallState.noReply:
        _close();
        break;
      case CallState.calling:
        // _startCalling();
        break;
      case CallState.connecting:
        break;
      // case CallState.noReply:
      //   break;
    }
  }

  _onTapPickup() async {
    setState(() {
      _state = CallState.connecting;
    });
    var certificate = await widget.onTapPickup!.call();
    await _connect(certificate['liveURL'], certificate['token']);
  }

  _onTapHangup() async {
    await widget.onTapHangup?.call(_duration, true).whenComplete(_close);
  }

  _onTapCancel() async {
    await widget.onTapCancel?.call().whenComplete(_close);
  }

  _onTapReject() async {
    await widget.onTapReject?.call().whenComplete(_close);
  }

  _close() async {
    // Navigator.pop(context);
    widget.onClose?.call();
  }

  int get _length {
    int remote = _room?.participants.length ?? 0;
    int local = _room?.localParticipant != null ? 1 : 0;
    return remote + local;
  }

  void _onTapMinimize() {
    setState(() {
      _minimize = true;
    });
  }

  void _onTapMaximize() {
    setState(() {
      _minimize = false;
    });
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          AnimatedScale(
            scale: _minimize ? 0 : 1,
            alignment: const Alignment(0.9, -0.8),
            duration: const Duration(milliseconds: 200),
            child: _buildMaximizeView(),
          ),
          if (_minimize)
            Positioned(
              top: 48.h,
              right: 13.w,
              child: SmallWindowView(
                state: isCalling ? CallState.calling : _state,
                opacity: _minimize ? 1 : 0,
                onTapMaximize: _onTapMaximize,
                child: isVideoCalling
                    ? SizedBox(
                        width: 120.w,
                        height: 180.h,
                        child:
                            ParticipantView.widgetFor(_room!.localParticipant!),
                      )
                    : null,
              ),
            ),
        ],
      );

  Widget _buildMaximizeView() => Material(
        color: const Color(0xFF262626),
        child: ControlsWidget(
          state: _state,
          type: widget.type,
          roomSubject: roomSubject,
          stateSubject: stateSubject,
          onBack: () => _close(),
          onHangup: () => _onTapHangup(),
          onPickup: () => _onTapPickup(),
          onReject: () => _onTapReject(),
          onMinimize: _onTapMinimize,
          child: _length == 0
              ? (_state == CallState.beCalled
                  ? BeCalledView(
                      inviterUserID: widget.inviterUserID,
                      inviteeUserIDList: widget.inviteeUserIDList,
                      groupInfo: _groupInfo,
                      memberInfoList: _memberInfoList,
                      type: widget.type,
                    )
                  : const LoadingWidget())
              : Column(
                  children: [
                    Expanded(child: CallingView(length: _length, room: _room!)),
                    DurationView(
                      callingDuration: u.Utils.seconds2HMS(_duration),
                    ),
                  ],
                ),
        ),
      );

  bool get isVideoCalling => isCalling && widget.type == CallType.video;

  bool get isCalling =>
      _state == CallState.calling || _state == CallState.beAccepted;
}
