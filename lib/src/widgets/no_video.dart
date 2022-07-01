import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_openim_live/src/utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

import '../theme.dart';

class NoVideoWidget extends StatelessWidget {
  //
  const NoVideoWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        alignment: Alignment.center,
        child: LayoutBuilder(
          builder: (ctx, constraints) => Icon(
            EvaIcons.videoOffOutline,
            color: LKColors.lkBlue,
            size: math.min(constraints.maxHeight, constraints.maxWidth) * 0.3,
          ),
        ),
      );
}

class NoVideoAvatarWidget extends StatelessWidget {
  //
  const NoVideoAvatarWidget({Key? key, this.faceURL}) : super(key: key);
  final String? faceURL;

  //
  bool get _isURL => null != faceURL && Utils.isURL(faceURL!);

  @override
  Widget build(BuildContext context) => _isURL
      ? CachedNetworkImage(
          imageUrl: faceURL!,
          // width: 1.sw / 3,
          memCacheWidth: 1.sw ~/ 2,
          fit: BoxFit.cover,
        )
      : const NoVideoWidget();
}

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Lottie.asset(
            'assets/json/loading.json',
            width: 50.w,
            package: 'flutter_openim_live',
          ),
        )
      ],
    );
  }
}
