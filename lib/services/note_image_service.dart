import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class NoteImageService {
  final ImagePicker _picker;

  NoteImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  Future<String?> pickAndPersist(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked == null) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'note_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final ext =
        p.extension(picked.path).isNotEmpty ? p.extension(picked.path) : '.jpg';
    final fileName = '${const Uuid().v4()}$ext';
    final dest = File(p.join(imagesDir.path, fileName));
    await File(picked.path).copy(dest.path);
    return dest.path;
  }

  Future<void> deleteIfPresent(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // A missing or locked local image should not block note changes.
    }
  }
}
