import 'dart:io';
import 'package:flutter/widgets.dart';

Widget? buildLocalImageWidgetImpl(
  String? imagePath, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  if (imagePath == null || imagePath.isEmpty) return null;
  final file = File(imagePath);
  if (!file.existsSync()) return null;

  return Image.file(
    file,
    width: width,
    height: height,
    fit: fit,
  );
}
