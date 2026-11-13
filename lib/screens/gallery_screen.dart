import 'dart:io';

import 'package:flutter/material.dart';

import '../services/media_service.dart';

/// صفحه گالری — نمایش عکس‌ها و فیلم‌های ثبت‌شده
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => GalleryScreenState();
}

// نکته: public است تا از MainShell با GlobalKey تازه‌سازی شود.
class GalleryScreenState extends State<GalleryScreen> {
  List<File> _files = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  /// خواندن دوباره فایل‌ها از حافظه
  Future<void> refresh() async {
    final files = await MediaService.listMedia();
    if (mounted) {
      setState(() {
        _files = files;
        _loading = false;
      });
    }
  }

  Future<void> _delete(File file) async {
    await file.delete();
    await refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('گالری پروژه')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? const Center(
                  child: Text(
                    'هنوز عکسی ثبت نشده\nاز صفحه دوربین شروع کن 📸',
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

  /// نمایش تمام‌صفحه عکس + دکمه حذف
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
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'پخش فیلم در نسخه بعدی اضافه می‌شود 🎬',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : InteractiveViewer(child: Image.file(file)),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  Navigator.pop(context);
                  _delete(file);
                },
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
}
