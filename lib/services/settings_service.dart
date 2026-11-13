import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

/// خواندن و ذخیره‌کردن تنظیمات در حافظه خود دستگاه
class SettingsService {
  static const _kCustom = 'custom_text';
  static const _kGps = 'use_gps';
  static const _kJalali = 'use_jalali';
  static const _kOnTop = 'stamp_on_top';

  /// بارگذاری تنظیمات ذخیره‌شده (اگر نبود، مقادیر پیش‌فرض)
  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      customText: prefs.getString(_kCustom) ?? '',
      useGps: prefs.getBool(_kGps) ?? true,
      useJalali: prefs.getBool(_kJalali) ?? true,
      stampOnTop: prefs.getBool(_kOnTop) ?? false,
    );
  }

  /// ذخیره تنظیمات
  static Future<void> save(AppSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCustom, s.customText);
    await prefs.setBool(_kGps, s.useGps);
    await prefs.setBool(_kJalali, s.useJalali);
    await prefs.setBool(_kOnTop, s.stampOnTop);
  }
}
