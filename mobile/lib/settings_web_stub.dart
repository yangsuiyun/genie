// Stub for non-web platforms
import 'dart:typed_data';

void downloadFile(Uint8List bytes, String filename) {
  throw UnsupportedError('File download is only supported on web');
}

Future<String?> uploadFile() async {
  throw UnsupportedError('File upload is only supported on web');
}
