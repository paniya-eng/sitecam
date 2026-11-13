import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// سرویس «سوزاندن» مُهر روی عکس
///
/// چرا از Canvas خود فلاتر استفاده می‌کنیم؟
/// چون متن فارسی (راست‌به‌چپ) با پکیج‌های معمول پردازش عکس درست رندر نمی‌شود
/// (حروف جدا جدا و برعکس نمایش داده می‌شوند)، ولی Canvas فلاتر فارسی را
/// کاملاً صحیح و با فونت وزیرمتن نمایش می‌دهد.
class StampService {
  static bool _fontLoaded = false;

  /// بارگذاری فونت وزیرمتن برای رسم روی Canvas
  static Future<void> _ensureFont() async {
    if (_fontLoaded) return;
    final loader = FontLoader('Vazirmatn')
      ..addBundle(rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf'));
    await loader.load();
    _fontLoaded = true;
  }

  /// مُهر را روی عکس می‌سوزاند و فایل جدید (PNG) را برمی‌گرداند.
  ///
  /// [lines] خطوط متن مُهر است (نام پروژه، تاریخ، GPS، متن دلخواه)
  /// [stampOnTop] اگر true باشد مُهر بالای عکس قرار می‌گیرد، وگرنه پایین.
  static Future<File> burnStamp({
    required File photoFile,
    required List<String> lines,
    required bool stampOnTop,
  }) async {
    await _ensureFont();

    // ۱) عکس را به تصویر قابل رسم تبدیل می‌کنیم
    final bytes = await photoFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final photo = frame.image;
    final w = photo.width.toDouble();
    final h = photo.height.toDouble();

    // ۲) بوم نقاشی را می‌سازیم و عکس اصلی را روی آن می‌کشیم
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(photo, Offset.zero);

    // ۳) اندازه نوار مُهر را بر اساس تعداد خطوط حساب می‌کنیم
    final fontSize = w * 0.033;
    final lineHeight = fontSize * 1.55;
    final barHeight = lineHeight * lines.length + fontSize * 0.9;
    final barY = stampOnTop ? 0.0 : h - barHeight;

    // نوار نیمه‌شفاف مشکی پشت متن
    canvas.drawRect(
      Rect.fromLTWH(0, barY, w, barHeight),
      Paint()..color = Colors.black.withOpacity(0.55),
    );

    // ۴) خط‌به‌خط متن مُهر را می‌نویسیم (راست‌چین و فارسی)
    for (var i = 0; i < lines.length; i++) {
      final builder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          textAlign: TextAlign.right,
          fontSize: fontSize,
          fontFamily: 'Vazirmatn',
          textDirection: TextDirection.rtl,
        ),
      )
        ..pushStyle(ui.TextStyle(color: Colors.white, fontFamily: 'Vazirmatn'))
        ..addText(lines[i]);
      final paragraph = builder.build();
      paragraph.layout(ui.ParagraphConstraints(width: w - fontSize * 1.2));
      canvas.drawParagraph(
        paragraph,
        Offset(fontSize * 0.6, barY + fontSize * 0.45 + i * lineHeight),
      );
    }

    // ۵) نتیجه نهایی را به PNG تبدیل و در فایل جدید ذخیره می‌کنیم
    final picture = recorder.endRecording();
    final result = await picture.toImage(photo.width, photo.height);
    final byteData = await result.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    final outPath =
        photoFile.path.replaceFirst(RegExp(r'\.jpe?g$'), '_stamped.png');
    final outFile = File(outPath);
    await outFile.writeAsBytes(pngBytes);
    return outFile;
  }
}
