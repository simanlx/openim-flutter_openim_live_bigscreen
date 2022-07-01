import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Button extends StatelessWidget {
  const Button({
    Key? key,
    required this.text,
    required this.icon,
    this.decoration,
    this.onTap,
    this.width,
    this.height,
  }) : super(key: key);
  final String text;
  final String icon;
  final double? width;
  final double? height;
  final Decoration? decoration;
  final Future Function()? onTap;

  Button.mic({
    Key? key,
    bool open = true,
    this.onTap,
  })  : decoration = BoxDecoration(
          color: open ? const Color(0xFFFFFFFF) : null,
          shape: BoxShape.circle,
          border: open
              ? null
              : Border.all(
                  color: const Color(0xFF656564),
                  width: 2,
                ),
        ),
        icon = open ? "mic_open" : "mic_close",
        text = open ? '麦克风已开' : '麦克风已关',
        width = 22.h,
        height = 24.h,
        super(key: key);

  Button.speaker({
    Key? key,
    bool open = true,
    this.onTap,
  })  : decoration = BoxDecoration(
          color: open ? const Color(0xFFFFFFFF) : null,
          shape: BoxShape.circle,
          border: open
              ? null
              : Border.all(
                  color: const Color(0xFF656564),
                  width: 2,
                ),
        ),
        icon = open ? "speaker_open" : "speaker_close",
        text = open ? '扬声器已开' : '扬声器已关',
        width = 22.h,
        height = 22.h,
        super(key: key);

  Button.hangUp({
    Key? key,
    this.onTap,
    int type = 1,
  })  : decoration = const BoxDecoration(
          color: Color(0xFFfb4942),
          shape: BoxShape.circle,
        ),
        icon = "hang_up",
        text = type == 1 ? '取消' : (type == 2 ? '拒绝' : '挂断'),
        width = 30.h,
        height = 12.h,
        super(key: key);

  Button.pickUp({
    Key? key,
    this.onTap,
  })  : decoration = const BoxDecoration(
          color: Color(0xFF2be2a2),
          shape: BoxShape.circle,
        ),
        icon = "pick_up",
        text = '接听',
        width = 26.h,
        height = 26.h,
        super(key: key);

  Button.turnCamera({
    Key? key,
    this.onTap,
  })  : decoration = const BoxDecoration(
          color: Color(0x80000000),
          shape: BoxShape.circle,
        ),
        icon = "turn_camera",
        text = '切换摄像头',
        width = 28.h,
        height = 28.h,
        super(key: key);

  @override
  Widget build(BuildContext context) => _Debounce(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64.h,
              height: 64.h,
              decoration: decoration,
              child: Center(
                child: Image.asset(
                  'assets/images/$icon.webp',
                  width: width,
                  height: height,
                  package: 'flutter_openim_live',
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 10.h),
              constraints: BoxConstraints(maxWidth: 80.w),
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: const Color(0xFFFFFFFF),
                ),
              ),
            ),
          ],
        ),
      );
}

class SimpleButton extends StatelessWidget {
  const SimpleButton({
    Key? key,
    required this.icon,
    this.open = true,
    this.onTap,
    this.height,
    this.width,
  }) : super(key: key);
  final String icon;
  final double? width;
  final double? height;
  final bool open;
  final Function()? onTap;

  SimpleButton.video({
    Key? key,
    this.onTap,
    this.open = true,
  })  : icon = open
            ? 'assets/images/video_open.webp'
            : 'assets/images/video_close.webp',
        width = open ? 28.w : 33.w,
        height = open ? 26.h : 30.w,
        super(key: key);

  SimpleButton.back({
    Key? key,
    this.onTap,
  })  : icon = 'assets/images/back.webp',
        width = 12.w,
        height = 21.h,
        open = true,
        super(key: key);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Image.asset(
          icon,
          width: width,
          height: height,
          package: 'flutter_openim_live',
        ),
      );
}

class _Debounce extends StatefulWidget {
  const _Debounce({Key? key, required this.child, this.onTap})
      : super(key: key);
  final Future Function()? onTap;
  final Widget child;

  @override
  State<_Debounce> createState() => _DebounceState();
}

class _DebounceState extends State<_Debounce> {
  bool _enabled = true;

  void _onClick() {
    if (!_enabled) return;
    _enabled = false;
    widget.onTap?.call().whenComplete(() {
      setState(() {
        _enabled = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onClick,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
