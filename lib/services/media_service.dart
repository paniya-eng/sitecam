import 'dart:io';

import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

/// ذخیره و خواندن فایل‌های عکس/فیلم اپ
///
/// فایل‌ها بر اساس پروژه جدا می‌شوند:
///   پوشه‌داخلی/sitecam/<شناسه-پروژه>/عکس.png
/// عکس‌های نسخه‌های قدیمی که در ریشه پوشه بودند نیز
/// در «پروژه پیش‌فرض» قابل مشاهده‌اند.
class MediaService {
  /// پوشه اصلی اپ
  static Future<Directory> appDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/sitecam');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// پوشه اختصاصی هر پروژه
  static Future<Directory> projectDir(String projectId) async {
    final base = await appDir();
    final dir = Directory('${base.path}/$projectId');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// کپی فایل به پوشه اپ (داخل پوشه پروژه) و برگرداندن مسیر نهایی
  static Future<File> saveToAppDir(File file, {String? projectId}) async {
    final dir =
        projectId == null ? await appDir() : await projectDir(projectId);
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

  /// لیست عکس‌ها و فیلم‌های یک پروژه (جدیدترین اول)
  /// اگر projectId داده نشود، همه فایل‌های ریشه برگردانده می‌شود.
  static Future<List<File>> listMedia({String? projectId}) async {
    final dirs = <Directory>[];
    if (projectId == null) {
      dirs.add(await appDir());
    } else {
      dirs.add(await projectDir(projectId));
      if (projectId == 'default') {
        // سازگاری با عکس‌های قدیمی ذخیره‌شده در ریشه پوشه
        dirs.add(await appDir());
      }
    }

    final files = <File>[];
    for (final d in dirs) {
      files.addAll(
        d
            .listSync()
            .whereType<File>()
            .where(_isMediaFile),
      );
    }
    files.sort(
      (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
    );
    return files;
  }

  /// تعداد فایل‌های یک پروژه
  static Future<int> countMedia(String projectId) async {
    final files = await listMedia(projectId: projectId);
    return files.length;
  }

  /// حذف پوشه یک پروژه و همه فایل‌های داخلش
  static Future<void> deleteProjectFolder(String projectId) async {
    final base = await appDir();
    final dir = Directory('${base.path}/$projectId');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  static bool _isMediaFile(File f) {
    final p = f.path.toLowerCase();
    return p.endsWith('.png') ||
        p.endsWith('.jpg') ||
        p.endsWith('.jpeg') ||
        p.endsWith('.mp4');
  }
}
