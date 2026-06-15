import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

Future<void> downloadBytes(String filename, List<int> bytes) async {
  final uint8 = Uint8List.fromList(bytes);
  final blob = web.Blob(
    [uint8.buffer.toJS].toJS,
    web.BlobPropertyBag(type: 'application/octet-stream'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}