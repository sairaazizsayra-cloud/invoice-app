import 'dart:typed_data';

Future<String> saveBytes({
  required String subdirectory,
  required String fileName,
  required Uint8List bytes,
}) async {
  throw UnsupportedError('Local file save is not available on this platform.');
}
