import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_openim_live/flutter_openim_live.dart';
import 'package:flutter_openim_live/src/group/widgets/participant.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../widgets/avatar.dart';

class CallingView extends StatelessWidget {
  const CallingView({
    Key? key,
    required this.length,
    required this.room,
  }) : super(key: key);
  final int length;
  final Room room;

  @override
  Widget build(BuildContext context) => GridView.builder(
        itemCount: length,
        padding: EdgeInsets.symmetric(
          horizontal: 22.w,
          vertical: 17.h,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 4.h,
          crossAxisSpacing: 4.w,
          childAspectRatio: 1.0,
        ),
        itemBuilder: (_, i) {
          if (room.localParticipant != null && i == 0) {
            return ParticipantWidget.widgetFor(room.localParticipant!);
          }
          return ParticipantWidget.widgetFor(
            room.participants.values.elementAt(i - 1),
          );
        },
      );
}

class BeCalledView extends StatelessWidget {
  const BeCalledView({
    Key? key,
    required this.inviterUserID,
    required this.inviteeUserIDList,
    required this.type,
    this.memberInfoList,
    this.groupInfo,
  }) : super(key: key);
  final String inviterUserID;
  final List<String> inviteeUserIDList;
  final List<Map>? memberInfoList;
  final Map? groupInfo;
  final CallType type;

  String _findNickname(String userID) =>
      _findMemberInfo(userID)?['nickname'] ?? userID;

  String? _findFaceURL(String userID) => _findMemberInfo(userID)?['faceURL'];

  Map? _findMemberInfo(String userID) =>
      memberInfoList?.firstWhereOrNull((e) => e['userID'] == userID);

  List<String> get _allMember => [inviterUserID, ...inviteeUserIDList];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 22.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 33.h,
          ),
          Row(
            children: [
              Avatar(
                url: groupInfo?['faceURL'],
                size: 48.h,
              ),
              SizedBox(
                width: 12.w,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_findNickname(inviterUserID)}${type == CallType.audio ? '邀请你语音通话' : '邀请你视频通话'}',
                    style: TextStyle(
                      fontSize: 20.sp,
                      color: const Color(0xFFFFFFFF),
                    ),
                  ),
                  SizedBox(
                    height: 4.h,
                  ),
                  Text(
                    '${_allMember.length}${type == CallType.audio ? '人正在语音通话中' : '人正在视频通话中'}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFFFFFFFF),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(
            height: 56.h,
          ),
          Wrap(
            alignment: WrapAlignment.start,
            spacing: 30.w,
            runSpacing: 10.h,
            children: _allMember.map((e) => _buildMemberItemView(e)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberItemView(String userID) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Avatar(
            url: _findFaceURL(userID),
            size: 42.h,
          ),
          SizedBox(
            height: 10.h,
          ),
          Container(
            constraints: BoxConstraints(maxWidth: 45.h),
            child: Text(
              _findNickname(userID),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFFFFFFFF),
              ),
            ),
          ),
        ],
      );
}

class DurationView extends StatelessWidget {
  const DurationView({Key? key, required this.callingDuration})
      : super(key: key);
  final String callingDuration;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 20.h, bottom: 15.h),
      child: Text(
        callingDuration,
        style: TextStyle(
            fontSize: 18.sp,
            color: const Color(
              0xFFFFFFFF,
            )),
      ),
    );
  }
}
