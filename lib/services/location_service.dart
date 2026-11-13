import 'package:geolocator/geolocator.dart';

/// سرویس موقعیت GPS
class LocationService {
  /// موقعیت فعلی گوشی را برمی‌گرداند.
  /// اگر GPS خاموش باشد یا مجوز داده نشده باشد، null برمی‌گرداند.
  static Future<Position?> getCurrentPosition() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }

  /// فرمت‌کردن موقعیت برای نمایش روی مُهر عکس
  static String format(Position? pos) {
    if (pos == null) return 'GPS: —';
    return 'GPS: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
  }
}
