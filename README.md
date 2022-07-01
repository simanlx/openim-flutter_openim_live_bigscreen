```
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_openim_live/flutter_openim_live.dart';
import 'package:flutter_openim_widget/flutter_openim_widget.dart';
import 'package:get/get.dart';
import 'package:openim_enterprise_chat/src/sdk_extension/message_manager.dart';
import 'package:rxdart/rxdart.dart';

/// 信令
mixin OpenLive {
  var signalingSubject = PublishSubject<CallEvent>();
  var insertSignalingMessageSubject = PublishSubject<CallEvent>();
  var signalingMessageSubject = PublishSubject<SignalingMessageEvent>();

  onInitLive() {
    _signalingListener();
    _insertSignalingMessageListener();
  }

  onCloseLive() {
    signalingSubject.close();
    insertSignalingMessageSubject.close();
    signalingMessageSubject.close();
  }

  void _signalingListener() {
    signalingSubject.stream.listen((event) {
      var iInfo = (event.data as SignalingInfo).invitation;
      var type = iInfo?.mediaType == 'audio' ? CallType.audio : CallType.video;
      var obj = iInfo?.sessionType == 2 ? CallObj.group : CallObj.single;
      if (event.state == CallState.beCalled) {
        LiveClient.call(
          ctx: Get.overlayContext!,
          eventChangedSubject: signalingSubject,
          inviteeUserIDList: iInfo!.inviteeUserIDList!,
          inviterUserID: iInfo.inviterUserID!,
          groupID: iInfo.groupID,
          type: type,
          obj: obj,
          initState: CallState.beCalled,
          syncUserInfo: syncUserInfo,
          syncGroupInfo: syncGroupInfo,
          syncGroupMemberInfo: syncGroupMemberInfo,
          onTapPickup: () => onTapPickup(
            SignalingInfo(opUserID: OpenIM.iMManager.uid, invitation: iInfo),
          ),
          onTapReject: () => onTapReject(
            SignalingInfo(opUserID: OpenIM.iMManager.uid, invitation: iInfo),
          ),
          onTapHangup: (duration) async {
            insertSignalingMessageSubject.add(CallEvent(
              CallState.hangup,
              SignalingInfo(opUserID: OpenIM.iMManager.uid, invitation: iInfo),
              fields: duration,
            ));
          },
        );
      } else if (event.state == CallState.beRejected) {
        insertSignalingMessageSubject.add(event);
      } else if (event.state == CallState.beHangup) {
        insertSignalingMessageSubject.add(event);
      } else if (event.state == CallState.beCanceled) {
        insertSignalingMessageSubject.add(event);
      }
    });
  }

  _insertSignalingMessageListener() {
    insertSignalingMessageSubject.listen((value) {
      _insertMessage(
        state: value.state,
        signalingInfo: value.data,
        duration: value.fields ?? 0,
      );
    });
  }

  call(
    CallObj obj,
    CallType type,
    String? groupID,
    List<String> inviteeUserIDList,
  ) {
    var mediaType = type == CallType.audio ? 'audio' : 'video';
    var signal = SignalingInfo(
      opUserID: OpenIM.iMManager.uid,
      invitation: InvitationInfo(
        inviterUserID: OpenIM.iMManager.uid,
        inviteeUserIDList: inviteeUserIDList,
        timeout: 30,
        mediaType: mediaType,
        sessionType: obj == CallObj.single ? 1 : 2,
        platformID: Platform.isAndroid ? 2 : 1,
        groupID: groupID,
      ),
    );

    LiveClient.call(
      ctx: Get.overlayContext!,
      eventChangedSubject: signalingSubject,
      inviterUserID: OpenIM.iMManager.uid,
      groupID: groupID,
      inviteeUserIDList: inviteeUserIDList,
      obj: obj,
      type: type,
      initState: CallState.call,
      onDialSingle: () => onDialSingle(signal),
      onDialGroup: () => onDialGroup(signal),
      onTapCancel: () => onTapCancel(signal),
      onTapHangup: (duration) async {
        insertSignalingMessageSubject.add(CallEvent(
          CallState.hangup,
          signal,
          fields: duration,
        ));
      },
      syncUserInfo: syncUserInfo,
      syncGroupInfo: syncGroupInfo,
      syncGroupMemberInfo: syncGroupMemberInfo,
    );
  }

  /// 拨向单人
  onDialSingle(SignalingInfo signaling) async {
    var info = await OpenIM.iMManager.signalingManager.signalingInvite(
      info: signaling,
    );
    return info.toJson();
  }

  /// 拨向多人
  onDialGroup(SignalingInfo signaling) async {
    var info = await OpenIM.iMManager.signalingManager.signalingInviteInGroup(
      info: signaling..invitation?.timeout = 1 * 60 * 60,
    );
    return info.toJson();
  }

  /// 接听
  onTapPickup(SignalingInfo signaling) async {
    var info = await OpenIM.iMManager.signalingManager.signalingAccept(
      info: signaling,
    );
    return info.toJson();
  }

  /// 拒绝
  onTapReject(SignalingInfo signaling) async {
    insertSignalingMessageSubject.add(CallEvent(CallState.reject, signaling));
    return OpenIM.iMManager.signalingManager.signalingReject(
      info: signaling,
    );
  }

  /// 取消
  onTapCancel(SignalingInfo signaling) async {
    insertSignalingMessageSubject.add(CallEvent(CallState.cancel, signaling));
    return OpenIM.iMManager.signalingManager.signalingCancel(
      info: signaling,
    );
  }

  /// 同步用户信息
  Future<Map?> syncUserInfo(userID) async {
    var list = await OpenIM.iMManager.userManager.getUsersInfo(
      uidList: [userID],
    );
    return list.map((e) => e.toJson()).firstOrNull;
  }

  /// 同步组信息
  Future<Map?> syncGroupInfo(groupID) async {
    var list = await OpenIM.iMManager.groupManager.getGroupsInfo(
      gidList: [groupID],
    );
    return list.map((e) => e.toJson()).firstOrNull;
  }

  /// 同步群成员信息
  Future<List<Map>?> syncGroupMemberInfo(groupID, userIDList) async {
    var list = await OpenIM.iMManager.groupManager.getGroupMembersInfo(
      groupId: groupID,
      uidList: userIDList,
    );
    return list.map((e) => e.toJson()).toList();
  }

  /// 自定义通话消息
  void _insertMessage({
    required CallState state,
    required SignalingInfo signalingInfo,
    // required CallType type,
    // required CallObj obj,
    // required String inviterUserID,
    // List<String>? inviteeUserIDList,
    // String? groupID,
    int duration = 0,
  }) async {
    (() async {
      var invitation = signalingInfo.invitation;
      var mediaType = invitation!.mediaType;
      var inviterUserID = invitation.inviterUserID;
      var inviteeUserID = invitation.inviteeUserIDList!.first;
      var groupID = invitation.groupID;
      print('----------state:${state.name}');
      print('----------mediaType:$mediaType');
      print('----------inviterUserID:$inviterUserID');
      print('----------inviteeUserIDList:$inviteeUserID');
      print('----------groupID:$groupID');
      var message = await OpenIM.iMManager.messageManager.createCallMessage(
        state: state.name,
        type: mediaType!,
        duration: duration,
      );
      switch (invitation.sessionType) {
        case 1:
          {
            var receiverID;
            if (inviterUserID != OpenIM.iMManager.uid) {
              receiverID = inviterUserID;
            } else {
              receiverID = inviteeUserID;
            }
            signalingMessageSubject.add(
              SignalingMessageEvent(message, 1, receiverID, null),
            );
            OpenIM.iMManager.messageManager.insertSingleMessageToLocalStorage(
              receiverID: receiverID,
              senderID: OpenIM.iMManager.uid,
              message: message
                ..status = 2
                ..isRead = true,
            );
          }
          break;
        case 2:
          {
            // signalingMessageSubject.add(
            //   SignalingMessageEvent(message, 2, null, groupID),
            // );
            // OpenIM.iMManager.messageManager.insertGroupMessageToLocalStorage(
            //   groupID: groupID!,
            //   senderID: inviterUserID,
            //   message: message..status = 2,
            // );
          }
          break;
      }
    })();
  }
}

class SignalingMessageEvent {
  Message message;
  String? userID;
  String? groupID;
  int sessionType;

  SignalingMessageEvent(
    this.message,
    this.sessionType,
    this.userID,
    this.groupID,
  );
}
```
