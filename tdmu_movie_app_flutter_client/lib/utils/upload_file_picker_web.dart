// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'upload_file_picker.dart';

Future<PickedUploadFile?> pickImageFile() {
  return _pickFile(accept: 'image/*');
}

Future<PickedUploadFile?> pickVideoFile() {
  return _pickFile(accept: 'video/*');
}

Future<PickedUploadFile?> _pickFile({required String accept}) {
  final completer = Completer<PickedUploadFile?>();
  final input = html.FileUploadInputElement()..accept = accept;

  input.onChange.listen((_) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }

    final file = files.first;
    final reader = html.FileReader();

    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result is! ByteBuffer) {
        completer.complete(null);
        return;
      }

      completer.complete(
        PickedUploadFile(name: file.name, bytes: Uint8List.view(result)),
      );
    });

    reader.onError.listen((_) {
      completer.completeError(
        Exception('Không thể đọc tệp ${file.name} trên trình duyệt.'),
      );
    });

    reader.readAsArrayBuffer(file);
  });

  input.click();
  return completer.future;
}
