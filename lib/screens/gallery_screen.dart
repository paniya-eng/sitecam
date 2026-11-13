import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/project.dart';
import '../services/media_service.dart';
import '../services/project_service.dart';
import '../services/report_service.dart';

/// صفحه گالری — نمایش عکس‌ها و فیلم‌های پروژه فعال
/// + ساختن گزارش تصویری PDF
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => GalleryScreenState();
}

// نکته: public است تا از MainShell با GlobalKey تازه‌سازی شود.
class GalleryScreenState extends State<GalleryScreen> {
  Project? _project;
  List<File> _files = [];
  bool _loading = true;
  bool _makingPdf = false;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  /// خواندن پروژه فعال و فایل‌های آن از حافظه
  Future<void> refresh() async {
    final project = await ProjectService.getActiveProject();
    final files = await MediaService.listMedia(projectId: project.id);
    if (mounted) {
      setState(() {
        _project = project;
        _files = files;
        _loading = false;
      });
    }
  }

  Future<void> _delete(File file) async {
    try {
      await file.delete();
    } catch (_) {}
    await refresh();
  }

  /// ساخت گزارش تصویری PDF از عکس‌های پروژه و اشتراک‌گذاری آن
  Future<void> _buildReport() async {
    final project = _project;
    if (project == null) return;

    // فقط عکس‌ها وارد گزارش می‌شوند (فیلم خیر)، از قدیم به جدید
    final photos = _files.where((f) => !f.path.endsWith('.mp4')).toList()
      ..sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

    if (photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('در این پروژه هنوز عکسی ثبت نشده')),
      );
      return;
    }

    setState(() => _makingPdf = true);
    try {
      final file = await ReportService.generate(
        project: project,
        photos: photos,
      );
      await ReportService.share(file);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('گزارش PDF ساخته شد ✅\n${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ساخت گزارش: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _makingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectName = _project?.name ?? 'گالری پروژه';
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('گالری پروژه'),
            Text(
              projectName,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          // دکمه ساخت گزارش PDF
          _makingPdf
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  tooltip: 'خروجی گزارش PDF',
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: _buildReport,
                ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? Center(
                  child: Text(
                    'در پروژه «$projectName» هنوز عکسی ثبت نشده\nاز صفحه دوربین شروع کن 📸',
                    textAlign: TextAlign.center,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: refresh,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      // در تبلت/ویندوز ستون‌های بیشتری نشان می‌دهیم
                      crossAxisCount:
                          MediaQuery.sizeOf(context).width > 700 ? 4 : 3,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemCount: _files.length,
                    itemBuilder: (context, i) {
                      final file = _files[i];
                      final isVideo = file.path.endsWith('.mp4');
                      return GestureDetector(
                        onTap: () => _showFull(context, file),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            isVideo
                                ? Container(
                                    color: Colors.black,
                                    child: const Center(
                                      child: Icon(
                                        Icons.play_circle_fill,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : Image.file(file, fit: BoxFit.cover),
                            if (isVideo)
                              const Positioned(
                                bottom: 4,
                                right: 4,
                                child: Icon(
                                  Icons.videocam,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  /// نمایش تمام‌صفحه عکس/فیلم + دکمه حذف
  void _showFull(BuildContext context, File file) {
    final isVideo = file.path.endsWith('.mp4');
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: isVideo
                  ? _VideoPlayerView(file: file)
                  : InteractiveViewer(child: Image.file(file)),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDelete(context, file),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// تأیید گرفتن قبل از حذف
  void _confirmDelete(BuildContext context, File file) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف فایل'),
        content: const Text('این فایل برای همیشه حذف می‌شود. ادامه می‌دهی؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // بستن پنجره تأیید
              Navigator.pop(context); // بستن نمایشگر
              _delete(file);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// پخش‌کننده فیلم داخل خود اپ (لمسی: لمس = پخش/توقف)
class _VideoPlayerView extends StatefulWidget {
  const _VideoPlayerView({required this.file});

  final File file;

  @override
  State<_VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<_VideoPlayerView> {
  late VideoPlayerController _controller;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file);
    _controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() => _ready = true);
          _controller.play();
        })
        .catchError((Object e) {
          if (mounted) setState(() => _error = e.toString());
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'پخش این فیلم ممکن نشد:\n$_error',
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (!_ready) {
      return const CircularProgressIndicator();
    }
    final ratio = _controller.value.aspectRatio == 0
        ? 16 / 9
        : _controller.value.aspectRatio;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_controller.value.isPlaying) {
            _controller.pause();
          } else {
            _controller.play();
          }
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: ratio,
            child: VideoPlayer(_controller),
          ),
          if (!_controller.value.isPlaying)
            const Icon(
              Icons.play_circle_fill,
              color: Colors.white70,
              size: 72,
            ),
        ],
      ),
    );
  }
}
