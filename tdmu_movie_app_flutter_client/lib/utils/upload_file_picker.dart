import 'upload_file_picker_stub.dart'
    if (dart.library.html) 'upload_file_picker_web.dart'
    as impl;

class PickedUploadFile {
  const PickedUploadFile({required this.name, required this.bytes});

  final String name;
  final List<int> bytes;
}

Future<PickedUploadFile?> pickImageFile() => impl.pickImageFile();

Future<PickedUploadFile?> pickVideoFile() => impl.pickVideoFile();
