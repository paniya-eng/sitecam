import 'dart:io';

import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

/// ذخیره و خواندن فایل‌های عکس/فیلم اپ
class MediaService {
  /// پوشه اختصاصی اپ برای ذخیره عکس‌ها (داخل حافظه داخلی گوشی)
  static Future<Directory> appDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/sitecam');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// کپی فایل به پوشه اپ و برگرداندن مسیر نهایی
  static Future<File> saveToAppDir(File file) async {
    final dir = await appDir();
    final name = file.path.split(Platform.pathSeparator).last;
    final dest = File('${dir.path}/$name');
    if (file.path != dest.path) {
      await file.copy(dest.path);
    }
    return dest;
  }

  /// ذخیره در گالری گوشی تا راحت با همکاران به اشتراک گذاشته شود
  static Future<bool> saveToGallery(File file) async {
    try {
      if (file.path.endsWith('.mp4')) {
        await Gal.putVideo(file.path);
      } else {
        await Gal.putImage(file.path);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// لیست عکس‌ها و فیلم‌های ذخیره‌شده (جدیدترین اول)
  static Future<List<File>> listMedia() async {
    final dir = await appDir();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) =>
            f.path.endsWith('.png') ||
            f.path.endsWith('.jpg') ||
            f.path.endsWith('.mp4'))
        .toList()
      ..sort((a, b) =>
          b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }
}
