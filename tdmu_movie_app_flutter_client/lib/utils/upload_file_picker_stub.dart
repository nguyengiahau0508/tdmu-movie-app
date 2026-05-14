import 'dart:io';
import 'package:file_picker/file_picker.dart';

import 'upload_file_picker.dart';

Future<PickedUploadFile?> pickImageFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: false,
    withData: true,
  );
  if (result == null || result.files.isEmpty) {
    return null;
  }

  final file = result.files.first;
  List<int>? bytes = file.bytes;

  if (bytes == null && file.path != null) {
    bytes = await File(file.path!).readAsBytes();
  }

  if (bytes == null) {
    return null;
  }

  return PickedUploadFile(name: file.name, bytes: bytes);
}

Future<PickedUploadFile?> pickVideoFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.video,
    allowMultiple: false,
    withData: true,
  );
  if (result == null || result.files.isEmpty) {
    return null;
  }

  final file = result.files.first;
  List<int>? bytes = file.bytes;

  if (bytes == null && file.path != null) {
    bytes = await File(file.path!).readAsBytes();
  }

  if (bytes == null) {
    return null;
  }

  return PickedUploadFile(name: file.name, bytes: bytes);
}
