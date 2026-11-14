import 'package:flutter/material.dart';

/// نمایش زنده مُهر روی پیش‌نمایش دوربین
/// تا کاربر قبل از عکس‌گرفتن ببیند دقیقاً چه چیزی روی عکس ثبت می‌شود.
class StampOverlay extends StatelessWidget {
  final List<String> lines; // خطوط متن مُهر
  final bool stampOnTop; // مُهر بالا باشد یا پایین؟

  const StampOverlay({
    super.key,
    required this.lines,
    required this.stampOnTop,
  });

  @override
  Widget build(BuildContext context) {
    final bar = Container(
      width: double.infinity,
      color: Colors.black.withOpacity(0.55),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end, // راست‌چین (فارسی)
        mainAxisSize: MainAxisSize.min,
        children: lines
            .map(
              (l) => Text(
                l,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            )
            .toList(),
      ),
    );

    return Positioned(
      left: 0,
      right: 0,
      top: stampOnTop ? 0 : null,
      bottom: stampOnTop ? null : 0,
      child: bar,
    );
  }
}
