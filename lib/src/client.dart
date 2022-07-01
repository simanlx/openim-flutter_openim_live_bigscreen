import 'package:flutter/material.dart';
import 'package:flutter_openim_live/src/utils.dart';
import 'package:rxdart/rxdart.dart';

import 'group/room.dart' as group;
import 'single/room.dart' as single;

enum CallType { audio, video }
enum CallObj { single, group }
enum CallState {
  call, // 主动邀请
  beCalled, // 被邀请
  reject, // 拒绝
  beRejected, // 被拒绝
  calling, // 通话中
  beAccepted, // 已接受
  hangup, // 主动挂断
  beHangup, // 被对方挂断
  connecting,
  noReply, // 无响应
  cancel, // 主动取消
  beCanceled, // 被取消
  timeout, //超时
}

class CallEvent {
  CallState state;
  dynamic data;
  dynamic fields;

  CallEvent(this.state, this.data, {this.fields});
}

class LiveClient {
  LiveClient._();

  /// 占线
  static bool isBusy = false;

  static String? currentRoomID;

  static void call({
    required BuildContext ctx,
    required PublishSubject<CallEvent> eventChangedSubject,
    String? roomID,
    CallState initState = CallState.call,
    CallType type = CallType.video,
    CallObj obj = CallObj.single,
    bool simulcast = true,
    required String inviterUserID,
    required List<String> inviteeUserIDList,
    String? groupID,
    Future Function()? onDialSingle,
    Future Function()? onDialGroup,
    Future Function()? onTapCancel,
    Future Function(int duration, bool isPositive)? onTapHangup,
    Future Function()? onTapPickup,
    Future Function()? onTapReject,
    Function()? onDisconnected,
    Future Function(String userID)? syncUserInfo,
    Future Function(String groupID)? syncGroupInfo,
    Future Function(String groupID, List<String> memberIDList)?
        syncGroupMemberInfo,
    bool autoPickup = false,
  }) {
    if (isBusy) return;
    _close();
    isBusy = true;
    currentRoomID = roomID;

    FocusScope.of(ctx).requestFocus(FocusNode());

    if (obj == CallObj.single) {
      _holder = OverlayEntry(
          builder: (context) => single.RoomPage(
                type: type,
                initState: initState,
                eventChangedSubject: eventChangedSubject,
                roomID: roomID,
                userID: initState == CallState.call
                    ? inviteeUserIDList.first
                    : inviterUserID,
                onDial: onDialSingle,
                onTapCancel: onTapCancel,
                onDisconnected: onDisconnected,
                onTapHangup: onTapHangup,
                onTapReject: onTapReject,
                onTapPickup: onTapPickup,
                onClose: _close,
                syncUserInfo: syncUserInfo,
                autoPickup: autoPickup,
                onBindRoomID: (roomID) => currentRoomID = roomID,
              ));
    } else {
      _holder = OverlayEntry(
          builder: (context) => group.RoomPage(
                type: type,
                initState: initState,
                eventChangedSubject: eventChangedSubject,
                roomID: roomID,
                inviterUserID: inviterUserID,
                inviteeUserIDList: inviteeUserIDList,
                groupID: groupID!,
                onDial: onDialGroup,
                onTapCancel: onTapCancel,
                onDisconnected: onDisconnected,
                onTapHangup: onTapHangup,
                onTapReject: onTapReject,
                onTapPickup: onTapPickup,
                syncGroupInfo: syncGroupInfo,
                syncGroupMemberInfo: syncGroupMemberInfo,
                onClose: _close,
                onBindRoomID: (roomID) => currentRoomID = roomID,
              ));
      /*
      Navigator.push<void>(
        ctx,
        MaterialPageRoute(
            builder: (_) => group.RoomPage(
                  type: type,
                  initState: initState,
                  eventChangedSubject: eventChangedSubject,
                  inviterUserID: inviterUserID,
                  inviteeUserIDList: inviteeUserIDList,
                  groupID: groupID!,
                  onDial: onDialGroup,
                  onTapCancel: onTapCancel,
                  onDisconnected: onDisconnected,
                  onTapHangup: onTapHangup,
                  onTapReject: onTapReject,
                  onTapPickup: onTapPickup,
                  syncGroupInfo: syncGroupInfo,
                  syncGroupMemberInfo: syncGroupMemberInfo,
                  // onClose: _close,
                )),
      ).whenComplete(() => _isBusy = false);
      */
    }
    Overlay.of(ctx)!.insert(_holder!);
  }

  static OverlayEntry? _holder;

  static void _close() {
    if (_holder != null) {
      _holder?.remove();
      _holder = null;
    }
    isBusy = false;
    currentRoomID = null;
  }

  /// 是否空闲可接受其他人的信令
  static bool dispatchSignaling(CallEvent event) {
    return !isBusy || isBusy && Utils.isSameRoom(event, currentRoomID);
  }
}
