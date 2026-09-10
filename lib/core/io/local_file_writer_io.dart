import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String> saveBytes({
  required String subdirectory,
  required String fileName,
  required Uint8List bytes,
}) async {
  final documents = await getApplicationDocumentsDirectory();
  final folder = Directory('${documents.path}/$subdirectory');
  if (!await folder.exists()) {
    await folder.create(recursive: true);
  }
  final file = File('${folder.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
