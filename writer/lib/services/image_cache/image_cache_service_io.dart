import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String?> cacheImageForPlatformImpl(String fullUrl, String fileName) async {
  final response = await http.get(Uri.parse(fullUrl));
  if (response.statusCode != 200) return null;

  final directory = await getApplicationDocumentsDirectory();
  final imagesDir = Directory(p.join(directory.path, 'images'));

  if (!await imagesDir.exists()) {
    await imagesDir.create(recursive: true);
  }

  final file = File(p.join(imagesDir.path, fileName));
  await file.writeAsBytes(response.bodyBytes);
  return file.path;
}

bool canReadLocalImagePathImpl() => true;
