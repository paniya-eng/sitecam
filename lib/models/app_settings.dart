/// مدل تنظیمات اپ — چیزهایی که کاربر یک‌بار وارد می‌کند
/// و روی همه عکس‌های بعدی مُهر می‌شود.
class AppSettings {
  String projectName; // نام پروژه (مثلاً: پروژه مسکونی سعادت‌آباد)
  String customText; // متن دلخواه (مثلاً: طبقه ۳ — بتن‌ریزی سقف)
  bool useGps; // نمایش موقعیت GPS روی مُهر؟
  bool useJalali; // تاریخ شمسی باشد یا میلادی؟
  bool stampOnTop; // مُهر بالای عکس باشد یا پایین؟

  AppSettings({
    this.projectName = '',
    this.customText = '',
    this.useGps = true,
    this.useJalali = true,
    this.stampOnTop = false,
  });
}
