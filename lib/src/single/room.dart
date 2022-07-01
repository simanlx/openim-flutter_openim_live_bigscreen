import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_openim_live/src/single/widgets/controls.dart';
import 'package:flutter_openim_live/src/timer.dart';
import 'package:flutter_openim_live/src/utils.dart' as u;
import 'package:flutter_openim_live/src/widgets/no_video.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:rxdart/rxdart.dart';

import '../client.dart';
import 'widgets/calling.dart';
import 'widgets/participant.dart';
import 'widgets/small_window.dart';

class RoomPage extends StatefulWidget {
  const RoomPage({
    Key? key,
    required this.type,
    required this.eventChangedSubject,
    this.roomID,
    this.initState = CallState.call,
    this.simulcast = true,
    required this.userID,
    this.onTapCancel,
    this.onTapHangup,
    this.onTapReject,
    this.onTapPickup,
    this.onDisconnected,
    this.onClose,
    this.onDial,
    this.syncUserInfo,
    this.autoPickup = false,
    this.onBindRoomID,
  }) : super(key: key);

  final CallType type;
  final CallState initState;
  final String? roomID;
  final bool simulcast;
  final String userID;
  final PublishSubject<CallEvent> eventChangedSubject;
  final Future Function()? onDial;
  final Future Function(String userID)? syncUserInfo;
  final Future Function()? onTapCancel;
  final Future Function(int duration, bool isPositive)? onTapHangup;
  final Future Function()? onTapPickup;
  final Future Function()? onTapReject;
  final Function()? onDisconnected;
  final Function()? onClose;
  final bool autoPickup;
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
  var _minimize = false;
  var _duration = 0;
  Timer? _callingTimer;
  String? _nickname;
  String? _faceURL;
  late Map _certificate;
  String? _roomID;
  StreamSubscription? _subs;

  @override
  void initState() {
    _state = widget.initState;
    _subs = widget.eventChangedSubject.stream
        .where((event) => u.Utils.isSameRoom(event, widget.roomID ?? _roomID))
        .listen(_onStateDidUpdate);
    widget.syncUserInfo?.call(widget.userID).then(_onUpdateUserInfo);
    if (_state == CallState.call) _onDail();
    if (widget.autoPickup) {
      _onTapPickup();
    }
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

  _onUpdateUserInfo(map) {
    if (!mounted) return;
    _nickname = map?['nickname'];
    _faceURL = map?['faceURL'];
    setState(() {});
  }

  void _onDail() async {
    _state = CallState.connecting;
    setState(() {});
    _certificate = await widget.onDial!.call();
    widget.onBindRoomID?.call(_roomID = _certificate["roomID"]);
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
        widget.onClose?.call();
      });
    })
    ..on<ParticipantConnectedEvent>((event) {})
    ..on<ParticipantDisconnectedEvent>((event) {
      _onTapHangup(false);
    })
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
    // _enableSpeakerphone();
  }

  /// 开启扬声器
  void _enableSpeakerphone() {
    LocalTrack? track;
    if (widget.type == CallType.video) {
      track = _room!.localParticipant?.videoTracks.firstOrNull?.track;
    } else {
      track = _room!.localParticipant?.audioTracks.firstOrNull?.track;
    }
    track?.mediaStreamTrack.enableSpeakerphone(true);
  }

  void _startCalling() {
    _state = CallState.calling;
    stateSubject.add(_state);
    _startCallingTimer();
  }

  void _onStateDidUpdate(CallEvent event) async {
    if (!mounted) return;
    stateSubject.add(_state = event.state);

    setState(() {});
    switch (_state) {
      case CallState.call:
        break;
      case CallState.reject:
        break;
      case CallState.cancel:
        break;
      case CallState.hangup:
        break;
      case CallState.beCalled:
        break;
      case CallState.beHangup:
      // _onTapHangup(false);
        break;
      case CallState.beRejected:
      case CallState.beCanceled:
        {
          try {
            var signalingInfo = event.data;
            var opUserID = signalingInfo.opUserID;
            var invitation = signalingInfo.invitation;
            var sessionType = invitation.sessionType;
            print('-------state:$_state----');
            print('-------opUserID:$opUserID----userID:${widget.userID}');
            print('-------sessionType:$sessionType----');
            if (opUserID != widget.userID || sessionType != 1) {
              return;
            }
          } catch (e) {
            print('----e:$e');
          }
          widget.onClose?.call();
          break;
        }

      case CallState.noReply:
        if ((_room?.participants.length ?? 0) > 0) {
          return;
        }
        widget.onClose?.call();
        break;
      case CallState.beAccepted:
        await _connect(_certificate['liveURL'], _certificate['token']);
        _startCalling();
        break;
      case CallState.calling:
        break;
      case CallState.connecting:
        break;
      case CallState.timeout:
        widget.onClose?.call();
        break;
    }
  }

  void _onRoomDidUpdate() {
    if (!mounted) return;
    roomSubject.add(_room!);
    setState(() {});
    // _sortParticipants();
  }

  void _startCallingTimer() {
    _callingTimer ??= Timer.periodic(
      const Duration(seconds: 1),
      (timer, count) {
        setState(() {
          _duration = count;
        });
      },
    );
  }

  _onTapPickup() async {
    print('------------onTapPickup---------连接中--------');
    setState(() {
      _state = CallState.connecting;
    });
    var certificate = await widget.onTapPickup!.call();
    await _connect(certificate['liveURL'], certificate['token']);
    print('------------onTapPickup---------连接成功--------');
    _startCalling();
  }

  _onTapHangup(bool isPositive) async {
    await widget.onTapHangup
        ?.call(_duration, isPositive)
        .whenComplete(() => widget.onClose?.call());
  }

  _onTapCancel() async {
    await widget.onTapCancel?.call().whenComplete(() => widget.onClose?.call());
  }

  _onTapReject() async {
    await widget.onTapReject?.call().whenComplete(() => widget.onClose?.call());
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
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedScale(
          scale: _minimize ? 0 : 1,
          alignment: const Alignment(0.9, -0.8),
          duration: const Duration(milliseconds: 200),
          child: Container(
            color: const Color(0xFF262626),
            child: Stack(
              children: [
                if (_room?.participants.isNotEmpty == true)
                  ParticipantView.widgetFor(_room!.participants.values.first),
                CallingView(
                  state: _state,
                  initState: widget.initState,
                  type: widget.type,
                  nickname: _nickname ?? '',
                  faceURL: _faceURL,
                  callingDuration: u.Utils.seconds2HMS(_duration),
                  onTapMaximizeBtn: _onTapMaximize,
                  isMinimize: _minimize,
                ),
                ControlsWidget(
                  state: _state,
                  type: widget.type,
                  roomSubject: roomSubject,
                  stateSubject: stateSubject,
                  onCancel: () => _onTapCancel(),
                  onHangup: () => _onTapHangup(true),
                  onPickup: () => _onTapPickup(),
                  onReject: () => _onTapReject(),
                  onMinimize: _onTapMinimize,
                ),
                if (_state != CallState.calling) const LoadingWidget(),
                if (_room?.localParticipant != null)
                  Positioned(
                    top: 60.h,
                    right: 3.w,
                    child: SizedBox(
                      width: 140.h,
                      height: 180.h,
                      child:
                          ParticipantView.widgetFor(_room!.localParticipant!),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_minimize)
          Positioned(
            top: 48.h,
            right: 13.w,
            child: SmallWindowView(
              state: _state,
              opacity: _minimize ? 1 : 0,
              onTapMaximize: _onTapMaximize,
              child: isVideoCalling &&
                      u.Utils.activeVideoTrack(
                              _room!.participants.values.first) !=
                          null
                  ? SizedBox(
                      width: 120.w,
                      height: 180.h,
                      child: ParticipantView.widgetFor(
                          _room!.participants.values.first),
                    )
                  : null,
            ),
          ),
      ],
    );
  }

  bool get isVideoCalling =>
      _state == CallState.calling && widget.type == CallType.video;
}
