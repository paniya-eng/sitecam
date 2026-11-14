import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/project.dart';

/// مدیریت پروژه‌ها (ساخت، انتخاب، حذف، تغییر نام)
///
/// لیست پروژه‌ها و «پروژه فعال» در حافظه گوشی ذخیره می‌شوند.
/// اولین بار که اپ باز شود، یک «پروژه پیش‌فرض» ساخته می‌شود تا
/// عکس‌های قدیمی (که بدون پروژه ذخیره شده‌اند) دیده شوند.
class ProjectService {
  static const String _projectsKey = 'sitecam_projects_v1';
  static const String _activeKey = 'sitecam_active_project_v1';
  static const String defaultProjectId = 'default';

  /// بارگذاری همه پروژه‌ها. اگر هیچ پروژه‌ای نبود، یکی می‌سازد.
  static Future<List<Project>> loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_projectsKey);

    if (raw == null || raw.isEmpty) {
      return _createDefault();
    }

    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => Project.fromJson(e as Map<String, dynamic>))
          .toList();
      if (list.isEmpty) {
        return _createDefault();
      }
      return list;
    } catch (_) {
      // داده ذخیره‌شده خراب بود — با پروژه پیش‌فرض شروع می‌کنیم
      return _createDefault();
    }
  }

  /// ساخت پروژه پیش‌فرض و فعال کردنش
  static Future<List<Project>> _createDefault() async {
    final def = Project(
      id: defaultProjectId,
      name: 'پروژه پیش‌فرض',
      createdAt: DateTime.now(),
    );
    await saveProjects([def]);
    await setActiveProjectId(def.id);
    return [def];
  }

  /// ذخیره کل لیست پروژه‌ها
  static Future<void> saveProjects(List<Project> projects) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(projects.map((p) => p.toJson()).toList());
    await prefs.setString(_projectsKey, json);
  }

  /// شناسه پروژه فعال (اگر تنظیم نشده بود، اولین پروژه برگردانده می‌شود)
  static Future<String> getActiveProjectId() async {
    final prefs = await SharedPreferences.getInstance();
    final projects = await loadProjects();
    final id = prefs.getString(_activeKey);
    if (id != null && projects.any((p) => p.id == id)) {
      return id;
    }
    return projects.first.id;
  }

  /// پروژه فعال را تنظیم کن
  static Future<void> setActiveProjectId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeKey, id);
  }

  /// خودِ پروژه فعال را برگردان
  static Future<Project> getActiveProject() async {
    final projects = await loadProjects();
    final id = await getActiveProjectId();
    return projects.firstWhere((p) => p.id == id,
        orElse: () => projects.first);
  }

  /// ساخت پروژه جدید (خودش فعال هم می‌شود)
  static Future<Project> createProject(String name) async {
    final projects = await loadProjects();
    final project = Project(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      createdAt: DateTime.now(),
    );
    projects.add(project);
    await saveProjects(projects);
    await setActiveProjectId(project.id);
    return project;
  }

  /// تغییر نام پروژه
  static Future<void> renameProject(String id, String newName) async {
    final projects = await loadProjects();
    for (final p in projects) {
      if (p.id == id) {
        p.name = newName.trim();
      }
    }
    await saveProjects(projects);
  }

  /// حذف پروژه از لیست.
  /// توجه: فایل‌های خود پروژه جداگانه با MediaService.deleteProjectFolder حذف می‌شوند.
  static Future<void> deleteProject(String id) async {
    final projects = await loadProjects();
    projects.removeWhere((p) => p.id == id);
    if (projects.isEmpty) {
      projects.add(Project(
        id: defaultProjectId,
        name: 'پروژه پیش‌فرض',
        createdAt: DateTime.now(),
      ));
    }
    await saveProjects(projects);
    // اگر پروژه فعال حذف شده بود، فعال را عوض کن
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_activeKey) == id) {
      await prefs.setString(_activeKey, projects.first.id);
    }
  }
}
