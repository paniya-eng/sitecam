import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../models/app_settings.dart';
import '../services/location_service.dart';
import '../services/media_service.dart';
import '../services/settings_service.dart';
import '../services/stamp_service.dart';
import '../widgets/stamp_overlay.dart';

/// صفحه دوربین — پیش‌نمایش زنده + مُهر + دکمه عکس/فیلم
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => CameraScreenState();
}

// نکته: این کلاس عمداً public است تا از صفحه اصلی (MainShell)
// با GlobalKey بتوانیم بعد از تغییر تنظیمات، آن را تازه‌سازی کنیم.
class CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  AppSettings _settings = AppSettings();
  Position? _position;
  bool _isRecording = false;
  bool _busy = false;
  String? _error;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _init();
    // هر ۲۰ ثانیه ساعت/تاریخ روی مُهر را تازه می‌کنیم
    _clockTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _init() async {
    _settings = await SettingsService.load();
    await _requestPermissions();
    await _initCamera();
    _refreshPosition();
    if (mounted) setState(() {});
  }

  /// وقتی کاربر از صفحه تنظیمات برمی‌گردد، تنظیمات جدید را می‌خوانیم
  Future<void> refreshSettings() async {
    _settings = await SettingsService.load();
    if (mounted) setState(() {});
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.location,
      Permission.photos, // ذخیره در گالری (اندروید و iOS)
      Permission.storage,
    ].request();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'دوربینی پیدا نشد');
        return;
      }
      _controller = CameraController(
        cameras.first, // دوربین پشتی
        ResolutionPreset.high,
        enableAudio: true,
      );
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      setState(() => _error = 'خطا در راه‌اندازی دوربین: $e');
    }
  }

  Future<void> _refreshPosition() async {
    final pos = await LocationService.getCurrentPosition();
    if (mounted) setState(() => _position = pos);
  }

  /// ساخت خطوط متن مُهر برای لحظه فعلی
  List<String> _stampLines() {
    final lines = <String>[];
    if (_settings.projectName.isNotEmpty) {
      lines.add('پروژه: ${_settings.projectName}');
    }
    lines.add(_formatNow());
    if (_settings.useGps) {
      lines.add(LocationService.format(_position));
    }
    if (_settings.customText.isNotEmpty) {
      lines.add(_settings.customText);
    }
    return lines;
  }

  /// فرمت تاریخ و ساعت (شمسی با اعداد فارسی، یا میلادی)
  String _formatNow() {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    if (_settings.useJalali) {
      final j = Jalali.fromDateTime(now);
      final date =
          '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}';
      return '${_toPersianDigits(date)}  ${_toPersianDigits('$hh:$mm')}';
    }
    return DateFormat('yyyy/MM/dd  HH:mm').format(now);
  }

  /// تبدیل اعداد انگلیسی به فارسی (۱۲۳)
  String _toPersianDigits(String s) => s.replaceAllMapped(
        RegExp(r'\d'),
        (m) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(m[0]!)],
      );

  /// گرفتن عکس + سوزاندن مُهر + ذخیره
  Future<void> _takePhoto() async {
    if (_controller == null || _busy) return;
    setState(() => _busy = true);
    try {
      final xfile = await _controller!.takePicture();
      var file = File(xfile.path);

      // سوزاندن مُهر روی عکس
      file = await StampService.burnStamp(
        photoFile: file,
        lines: _stampLines(),
        stampOnTop: _settings.stampOnTop,
      );

      // ذخیره در پوشه اپ + گالری گوشی
      file = await MediaService.saveToAppDir(file);
      await MediaService.saveToGallery(file);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('عکس با مُهر ذخیره شد ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ثبت عکس: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// شروع/توقف ضبط فیلم
  ///
  /// توجه: در این نسخه، مُهر به‌صورت زنده روی پیش‌نمایش دیده می‌شود
  /// ولی داخل فایل فیلم «سوزانده» نمی‌شود.
  /// سوزاندن مُهر روی فیلم در فاز ۲ اضافه می‌شود (با ffmpeg).
  Future<void> _toggleVideo() async {
    if (_controller == null || _busy) return;
    try {
      if (_isRecording) {
        final xfile = await _controller!.stopVideoRecording();
        final file = await MediaService.saveToAppDir(File(xfile.path));
        await MediaService.saveToGallery(file);
        setState(() => _isRecording = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فیلم ذخیره شد ✅')),
          );
        }
      } else {
        await _controller!.startVideoRecording();
        setState(() => _isRecording = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ضبط فیلم: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // پیش‌نمایش دوربین + مُهر زنده روی آن
    final preview = Stack(
      children: [
        Center(child: CameraPreview(_controller!)),
        StampOverlay(lines: _stampLines(), stampOnTop: _settings.stampOnTop),
        if (_isRecording)
          const Positioned(
            top: 12,
            left: 12,
            child: Row(
              children: [
                Icon(Icons.circle, color: Colors.red, size: 14),
                SizedBox(width: 6),
                Text(
                  'REC',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    // پنل دکمه‌ها و پیش‌نمایش متن مُهر
    final controls = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _stampLines()
                  .map(
                    (l) => Text(
                      l,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // دکمه فیلم
              FloatingActionButton(
                heroTag: 'video',
                onPressed: _toggleVideo,
                backgroundColor: _isRecording ? Colors.red : null,
                child: Icon(_isRecording ? Icons.stop : Icons.videocam),
              ),
              const SizedBox(width: 24),
              // دکمه بزرگ عکس
              GestureDetector(
                onTap: _takePhoto,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: _busy
                          ? const Center(child: CircularProgressIndicator())
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // دکمه تازه‌سازی GPS
              FloatingActionButton(
                heroTag: 'gps',
                onPressed: _refreshPosition,
                child: const Icon(Icons.my_location),
              ),
            ],
          ),
        ],
      ),
    );

    // چیدمان ریسپانسیو:
    // موبایل → ستونی (پیش‌نمایش بالا، دکمه‌ها پایین)
    // تبلت و ویندوز → کناری (پیش‌نمایش چپ، پنل دکمه‌ها راست)
    final width = MediaQuery.sizeOf(context).width;
    if (width > 700) {
      return Row(
        children: [
          Expanded(child: preview),
          SizedBox(width: 320, child: controls),
        ],
      );
    }
    return Column(
      children: [
        Expanded(child: preview),
        controls,
      ],
    );
  }
}
