import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_openim_live/src/utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Avatar extends StatelessWidget {
  const Avatar({
    Key? key,
    this.url,
    this.size,
  }) : super(key: key);
  final String? url;
  final double? size;

  @override
  Widget build(BuildContext context) => ClipRRect(
        child: url != null && Utils.isURL(url!)
            ? CachedNetworkImage(
                imageUrl: url!,
                width: size ?? 78.h,
                height: size ?? 78.h,
              )
            : Container(
                color: const Color(0xFF5496EB),
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: (size ?? 78.h) / 2,
                ),
                width: size ?? 78.h,
                height: size ?? 78.h,
                alignment: Alignment.center,
                // color: Colors.grey[400],
              ),
        borderRadius: BorderRadius.circular(6),
      );
}
