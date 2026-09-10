import 'dart:typed_data';

import 'package:invoice_pro/core/io/local_file_writer_stub.dart'
    if (dart.library.io) 'package:invoice_pro/core/io/local_file_writer_io.dart' as impl;

class LocalFileWriter {
  LocalFileWriter._();

  static Future<String> saveBytes({
    required String subdirectory,
    required String fileName,
    required Uint8List bytes,
  }) {
    return impl.saveBytes(subdirectory: subdirectory, fileName: fileName, bytes: bytes);
  }
}
