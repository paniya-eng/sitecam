import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../models/project.dart';

/// ساخت «گزارش تصویری PDF» از عکس‌های یک پروژه
///
/// نکته فنی: پکیج‌های PDF متن فارسی را درست شکل‌دهی نمی‌کنند
/// (حروف جدا جدا می‌افتند)، به همین دلیل هر صفحه گزارش را با
/// Canvas خود فلاتر به تصویر می‌کشیم (همان روشی که برای مُهر عکس
/// به‌کار می‌رود و فارسی را ۱۰۰٪ درست نمایش می‌دهد) و فقط
/// تصویر نهایی را داخل فایل PDF قرار می‌دهیم.
class ReportService {
  static const double _pageW = 1240; // A4 با کیفیت ~150 DPI
  static const double _pageH = 1754;
  static bool _fontLoaded = false;

  /// بارگذاری فونت وزیرمتن (عادی و توپر) برای رسم روی Canvas
  static Future<void> _ensureFont() async {
    if (_fontLoaded) return;
    final regular = FontLoader('Vazirmatn')
      ..addFont(rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf'));
    final bold = FontLoader('VazirmatnBold')
      ..addFont(rootBundle.load('assets/fonts/Vazirmatn-Bold.ttf'));
    await regular.load();
    await bold.load();
    _fontLoaded = true;
  }

  /// ساخت گزارش و ذخیره آن در پوشه داخلی اپ. مسیر فایل برگردانده می‌شود.
  static Future<File> generate({
    required Project project,
    required List<File> photos,
  }) async {
    await _ensureFont();

    // ۱) صفحه‌ها را به تصویر تبدیل می‌کنیم
    final pages = <Uint8List>[];
    pages.add(await _coverPage(project, photos.length));
    for (var i = 0; i < photos.length; i++) {
      pages.add(await _photoPage(photos[i], i + 1, photos.length, project));
    }

    // ۲) تصاویر را داخل PDF قرار می‌دهیم (A4)
    final doc = pw.Document();
    for (final bytes in pages) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Center(
            child: pw.Image(
              pw.MemoryImage(bytes),
              fit: pw.BoxFit.contain,
            ),
          ),
        ),
      );
    }

    // ۳) ذخیره در پوشه داخلی اپ
    final pdfBytes = await doc.save();
    final dir = await getApplicationDocumentsDirectory();
    final file =
        File('${dir.path}/sitecam_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(pdfBytes);
    return file;
  }

  /// باز کردن پنجره اشتراک‌گذاری/چاپ سیستم برای فایل PDF.
  /// اگر سیستم از اشتراک‌گذاری پشتیبانی نکند (مثلاً ویندوز)، برنامه کرش نمی‌کند.
  static Future<void> share(File pdfFile) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      await Printing.sharePdf(
        bytes: bytes,
        filename: pdfFile.path.split(Platform.pathSeparator).last,
      );
    } catch (_) {
      // مشکلی نیست — فایل در پوشه داخلی اپ باقی می‌ماند
    }
  }

  // ───────────────────────── صفحه‌ها ─────────────────────────

  /// صفحه جلد گزارش
  static Future<Uint8List> _coverPage(Project project, int photoCount) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // پس‌زمینه سفید
    canvas.drawRect(
      Rect.fromLTWH(0, 0, _pageW, _pageH),
      Paint()..color = const Color(0xFFFFFFFF),
    );

    // نوار بالایی نارنجی (مثل کلاه ایمنی کارگاه)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, _pageW, 300),
      Paint()..color = const Color(0xFFF59E0B),
    );
    await _drawText(
      canvas,
      'گزارش تصویری پروژه',
      const Rect.fromLTWH(60, 90, _pageW - 120, 130),
      fontSize: 86,
      color: const Color(0xFF3A2503),
      bold: true,
      align: TextAlign.center,
    );

    // نام پروژه در وسط صفحه
    await _drawText(
      canvas,
      project.name,
      const Rect.fromLTWH(80, 640, _pageW - 160, 260),
      fontSize: 96,
      color: const Color(0xFF1F2937),
      bold: true,
      align: TextAlign.center,
    );

    // خط جداکننده
    canvas.drawRect(
      Rect.fromLTWH(_pageW / 2 - 220, 950, 440, 10),
      Paint()..color = const Color(0xFFF59E0B),
    );

    // تاریخ گزارش (شمسی با اعداد فارسی)
    final now = DateTime.now();
    final j = Jalali.fromDateTime(now);
    final date = _toFa(
      '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}'
      '  ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
    );
    await _drawText(
      canvas,
      'تاریخ گزارش:  $date',
      const Rect.fromLTWH(80, 1030, _pageW - 160, 70),
      fontSize: 44,
      color: const Color(0xFF374151),
      align: TextAlign.center,
    );
    await _drawText(
      canvas,
      'تعداد عکس‌ها:  ${_toFa('$photoCount')}',
      const Rect.fromLTWH(80, 1120, _pageW - 160, 70),
      fontSize: 44,
      color: const Color(0xFF374151),
      align: TextAlign.center,
    );

    // پانویس
    await _drawText(
      canvas,
      'تهیه‌شده با اپ سایت‌کم — دوربین ثبت پروژه‌های ساختمانی',
      const Rect.fromLTWH(80, _pageH - 140, _pageW - 160, 50),
      fontSize: 30,
      color: const Color(0xFF9CA3AF),
      align: TextAlign.center,
    );

    return _toPng(recorder, _pageW.toInt(), _pageH.toInt());
  }

  /// صفحه هر عکس با سربرگ پروژه و شماره صفحه
  static Future<Uint8List> _photoPage(
    File photoFile,
    int index,
    int total,
    Project project,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // پس‌زمینه سفید
    canvas.drawRect(
      Rect.fromLTWH(0, 0, _pageW, _pageH),
      Paint()..color = const Color(0xFFFFFFFF),
    );

    // سربرگ: نوار کهربایی با نام پروژه
    canvas.drawRect(
      Rect.fromLTWH(0, 0, _pageW, 120),
      Paint()..color = const Color(0xFFF59E0B),
    );
    await _drawText(
      canvas,
      project.name,
      const Rect.fromLTWH(50, 32, _pageW - 100, 60),
      fontSize: 44,
      color: const Color(0xFF3A2503),
      bold: true,
      align: TextAlign.right,
    );

    // عکس را با حفظ نسبت در کادر می‌کشیم
    final bytes = await photoFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final image = (await codec.getNextFrame()).image;

    const area = Rect.fromLTWH(50, 170, _pageW - 100, _pageH - 430);
    final scale = min(
      area.width / image.width.toDouble(),
      area.height / image.height.toDouble(),
    );
    final drawW = image.width.toDouble() * scale;
    final drawH = image.height.toDouble() * scale;
    final dst = Rect.fromLTWH(
      area.left + (area.width - drawW) / 2,
      area.top + (area.height - drawH) / 2,
      drawW,
      drawH,
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dst,
      Paint()..filterQuality = FilterQuality.high,
    );

    // زیرنویس عکس: شماره + تاریخ فایل (شمسی)
    final dt = photoFile.lastModifiedSync();
    final j = Jalali.fromDateTime(dt);
    final date = _toFa(
      '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}'
      '  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
    );
    await _drawText(
      canvas,
      'عکس ${_toFa('$index')} از ${_toFa('$total')}   •   $date',
      const Rect.fromLTWH(50, _pageH - 210, _pageW - 100, 55),
      fontSize: 34,
      color: const Color(0xFF374151),
      align: TextAlign.right,
    );

    // پانویس: شماره صفحه
    await _drawText(
      canvas,
      'صفحه ${_toFa('${index + 1}')} از ${_toFa('${total + 1}')}',
      Rect.fromLTWH(50, _pageH - 115, _pageW - 100, 45),
      fontSize: 30,
      color: const Color(0xFF9CA3AF),
      align: TextAlign.center,
    );

    return _toPng(recorder, _pageW.toInt(), _pageH.toInt());
  }

  // ───────────────────── ابزارهای کمکی ─────────────────────

  /// رسم متن فارسی با چینش درست راست‌به‌چپ
  static Future<void> _drawText(
    Canvas canvas,
    String text,
    Rect rect, {
    required double fontSize,
    Color color = const Color(0xFF111111),
    bool bold = false,
    TextAlign align = TextAlign.right,
  }) async {
    final family = bold ? 'VazirmatnBold' : 'Vazirmatn';
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: align,
        fontSize: fontSize,
        fontFamily: family,
        textDirection: TextDirection.rtl,
      ),
    )
      ..pushStyle(ui.TextStyle(color: color, fontFamily: family))
      ..addText(text);
    final paragraph = builder.build();
    paragraph.layout(ui.ParagraphConstraints(width: rect.width));
    canvas.drawParagraph(paragraph, Offset(rect.left, rect.top));
  }

  /// تبدیل عدد انگلیسی به فارسی
  static String _toFa(String s) => s.replaceAllMapped(
        RegExp(r'\d'),
        (m) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(m[0]!)],
      );

  /// پایان ضبط و خروجی PNG
  static Future<Uint8List> _toPng(
    ui.PictureRecorder recorder,
    int width,
    int height,
  ) async {
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }
}
