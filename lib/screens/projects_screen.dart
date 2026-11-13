import 'package:flutter/material.dart';

import '../models/project.dart';
import '../services/media_service.dart';
import '../services/project_service.dart';

/// صفحه «پروژه‌ها» — مدیریت پروژه‌های ساختمانی
///
/// در این‌جا می‌توانی:
/// • پروژه جدید بسازی
/// • پروژه فعال را عوض کنی (گالری و دوربین همان پروژه را نشان می‌دهند)
/// • نام پروژه را تغییر دهی یا حذفش کنی
class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => ProjectsScreenState();
}

class ProjectsScreenState extends State<ProjectsScreen> {
  List<Project> _projects = [];
  String? _activeId;
  final Map<String, int> _counts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  /// خواندن همه پروژه‌ها + تعداد عکس هر پروژه
  Future<void> refresh() async {
    final projects = await ProjectService.loadProjects();
    final activeId = await ProjectService.getActiveProjectId();
    final counts = <String, int>{};
    for (final p in projects) {
      counts[p.id] = await MediaService.countMedia(p.id);
    }
    if (mounted) {
      setState(() {
        _projects = projects;
        _activeId = activeId;
        _counts
          ..clear()
          ..addAll(counts);
        _loading = false;
      });
    }
  }

  /// ساخت پروژه جدید
  Future<void> _addProject() async {
    final name = await _askName(title: 'پروژه جدید', initial: '');
    if (name == null || name.trim().isEmpty) return;
    await ProjectService.createProject(name);
    await refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('پروژه «${name.trim()}» ساخته و فعال شد ✅')),
      );
    }
  }

  /// تغییر نام پروژه
  Future<void> _renameProject(Project project) async {
    final name = await _askName(title: 'تغییر نام پروژه', initial: project.name);
    if (name == null || name.trim().isEmpty) return;
    await ProjectService.renameProject(project.id, name);
    await refresh();
  }

  /// حذف پروژه (به‌همراه همه عکس‌ها و فیلم‌هایش!)
  Future<void> _deleteProject(Project project) async {
    final count = _counts[project.id] ?? 0;
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف پروژه'),
        content: Text(
          'پروژه «${project.name}»'
          '${count > 0 ? ' و $count فایل داخلش' : ''}'
          ' برای همیشه حذف می‌شود.\nادامه می‌دهی؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (sure != true) return;

    // اول فایل‌ها، بعد پروژه
    await MediaService.deleteProjectFolder(project.id);
    await ProjectService.deleteProject(project.id);
    await refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('پروژه «${project.name}» حذف شد')),
      );
    }
  }

  /// انتخاب پروژه به‌عنوان پروژه فعال
  Future<void> _setActive(Project project) async {
    await ProjectService.setActiveProjectId(project.id);
    await refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('پروژه «${project.name}» فعال شد ✅')),
      );
    }
  }

  /// کادر پرسش نام (برای ساخت و تغییر نام)
  Future<String?> _askName({
    required String title,
    required String initial,
  }) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(
            labelText: 'نام پروژه',
            hintText: 'مثلاً: پروژه مسکونی سعادت‌آباد',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.pop(dialogContext, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('تأیید'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('پروژه‌ها')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_project',
        onPressed: _addProject,
        icon: const Icon(Icons.add),
        label: const Text('پروژه جدید'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // توضیح کوتاه بالای صفحه
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'پروژه‌ای که «فعال» باشد، عکس‌ها و فیلم‌های دوربین و گزارش PDF به آن پروژه مربوط می‌شود.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                for (final project in _projects) _buildProjectCard(project),
              ],
            ),
    );
  }

  /// کارت هر پروژه
  Widget _buildProjectCard(Project project) {
    final isActive = project.id == _activeId;
    final count = _counts[project.id] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isActive
            ? const BorderSide(color: Colors.amber, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.amber : Colors.blueGrey,
          child: Icon(
            isActive ? Icons.check : Icons.apartment,
            color: isActive ? Colors.black : Colors.white,
          ),
        ),
        title: Text(
          project.name,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text('$count فایل ثبت شده'),
        onTap: () => _setActive(project),
        trailing: Wrap(
          spacing: 0,
          children: [
            IconButton(
              tooltip: 'تغییر نام',
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _renameProject(project),
            ),
            IconButton(
              tooltip: 'حذف پروژه',
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _deleteProject(project),
            ),
          ],
        ),
      ),
    );
  }
}
