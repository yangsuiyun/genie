// Web-specific file operations
import 'dart:html' as html;
import 'dart:typed_data';

void downloadFile(Uint8List bytes, String filename) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

Future<String?> uploadFile() async {
  final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
  uploadInput.accept = '.json';
  uploadInput.click();

  await uploadInput.onChange.first;

  if (uploadInput.files!.isEmpty) return null;

  final file = uploadInput.files!.first;
  final reader = html.FileReader();
  reader.readAsText(file);
  await reader.onLoad.first;

  return reader.result as String?;
}
