/// مدل «پروژه» — اپ از چند پروژه پشتیبانی می‌کند.
/// هر پروژه عکس‌ها و فیلم‌های خودش را دارد.
class Project {
  final String id; // شناسه یکتا (زمان ساخت)
  String name; // نام پروژه (مثلاً: پروژه مسکونی سعادت‌آباد)
  final DateTime createdAt; // تاریخ ساخت

  Project({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  /// تبدیل به JSON برای ذخیره در حافظه گوشی
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  /// خواندن از JSON
  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
                DateTime.now(),
      );
}
