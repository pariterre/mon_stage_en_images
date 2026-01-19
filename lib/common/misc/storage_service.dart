import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mon_stage_en_images/common/models/user.dart';
import 'package:path/path.dart';

abstract class StorageService {
  static Future<Uint8List?> getImage(String imageUrl) async {
    return await FirebaseStorage.instance.ref(imageUrl).getData();
  }

  static Future<String> uploadImage(User student, XFile image) async {
    return await uploadFile(student, XFile(image.path));
  }

  static Future<String> uploadFile(User student, XFile file) async {
    final url = '/${student.id}/${file.hashCode}${extension(file.path)}';
    var ref = FirebaseStorage.instance.ref(url);

    kIsWeb
        ? await ref.putData(await file.readAsBytes(),
            SettableMetadata(contentType: 'image/jpeg'))
        : await ref.putFile(
            File(file.path), SettableMetadata(contentType: 'image/jpeg'));
    return url;
  }
}
