/// مدل تنظیمات اپ — چیزهایی که کاربر یک‌بار وارد می‌کند
/// و روی همه عکس‌های بعدی مُهر می‌شود.
///
/// نکته: نام پروژه دیگر این‌جا نیست؛ از تب «پروژه‌ها» انتخاب می‌شود.
class AppSettings {
  String customText; // متن دلخواه (مثلاً: طبقه ۳ — بتن‌ریزی سقف)
  bool useGps; // نمایش موقعیت GPS روی مُهر؟
  bool useJalali; // تاریخ شمسی باشد یا میلادی؟
  bool stampOnTop; // مُهر بالای عکس باشد یا پایین؟

  AppSettings({
    this.customText = '',
    this.useGps = true,
    this.useJalali = true,
    this.stampOnTop = false,
  });
}
