import 'package:flutter/widgets.dart';
import 'platform_local_image_io.dart'
    if (dart.library.html) 'platform_local_image_web.dart';

Widget? buildLocalImageWidget(
  String? imagePath, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  return buildLocalImageWidgetImpl(
    imagePath,
    width: width,
    height: height,
    fit: fit,
  );
}
