import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../client.dart';
import '../../widgets/avatar.dart';

class SmallWindowView extends StatelessWidget {
  const SmallWindowView({
    Key? key,
    required this.state,
    required this.opacity,
    this.url,
    this.onTapMaximize,
    this.child,
  }) : super(key: key);
  final CallState state;
  final String? url;
  final double opacity;
  final Function()? onTapMaximize;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: onTapMaximize,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: child ??
              Container(
                width: 80.w,
                height: 110.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF03091C),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Avatar(
                        size: 48.h,
                        url: url,
                      ),
                      SizedBox(
                        height: 6.h,
                      ),
                      Text(
                        state == CallState.call
                            ? '等待接听'
                            : (state == CallState.calling
                                ? '通话中'
                                : (state == CallState.connecting
                                    ? '连接中'
                                    : (state == CallState.beCalled
                                        ? '邀请你通话'
                                        : ''))),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFFFFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ),
      ),
    );
  }
}
