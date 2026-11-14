import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/project.dart';
import '../services/project_service.dart';
import '../services/settings_service.dart';

/// نسخه اپ (برای نمایش در «درباره برنامه»)
const String kAppVersion = '۱.۱.۰';

/// صفحه تنظیمات — متن دلخواه و گزینه‌های مُهر
/// (انتخاب پروژه در تب «پروژه‌ها» انجام می‌شود)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppSettings? _settings;
  Project? _activeProject;
  late TextEditingController _customCtrl;

  @override
  void initState() {
    super.initState();
    _customCtrl = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final s = await SettingsService.load();
    final p = await ProjectService.getActiveProject();
    if (!mounted) return;
    setState(() {
      _settings = s;
      _activeProject = p;
      _customCtrl.text = s.customText;
    });
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await SettingsService.save(_settings!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تنظیمات ذخیره شد ✅')),
      );
    }
  }

  /// نمایش پنجره «درباره برنامه»
  void _showAbout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(Icons.construction, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('سایت‌کم'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('دوربین ثبت پروژه‌های ساختمانی'),
            SizedBox(height: 8),
            Text('نسخه: $kAppVersion'),
            SizedBox(height: 12),
            Text(
              '• مُهر روی عکس: تاریخ شمسی/میلادی، ساعت، '
              'موقعیت GPS، نام پروژه و متن دلخواه\n'
              '• مدیریت چند پروژه با گالری جدا\n'
              '• خروجی گزارش تصویری PDF\n'
              '• پشتیبانی از اندروید، iOS و ویندوز',
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 12),
            Text(
              'ساخته‌شده با ❤️ برای کارگاه‌های ساختمانی',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: _settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // نمایش پروژه فعال (برای تغییر: تب پروژه‌ها)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.apartment, color: Colors.amber),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'پروژه فعال',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _activeProject?.name ?? 'بدون پروژه',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'تب «پروژه‌ها»',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _customCtrl,
                  decoration: const InputDecoration(
                    labelText: 'متن دلخواه روی مُهر',
                    hintText: 'مثلاً: طبقه ۳ — بتن‌ریزی سقف',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _settings!.customText = v,
                ),
                SwitchListTile(
                  title: const Text('نمایش موقعیت GPS'),
                  value: _settings!.useGps,
                  onChanged: (v) => setState(() => _settings!.useGps = v),
                ),
                SwitchListTile(
                  title: const Text('تاریخ شمسی'),
                  subtitle: const Text('خاموش = تاریخ میلادی'),
                  value: _settings!.useJalali,
                  onChanged: (v) => setState(() => _settings!.useJalali = v),
                ),
                SwitchListTile(
                  title: const Text('مُهر بالای عکس'),
                  subtitle: const Text('خاموش = مُهر پایین عکس'),
                  value: _settings!.stampOnTop,
                  onChanged: (v) => setState(() => _settings!.stampOnTop = v),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('ذخیره تنظیمات'),
                ),
                const SizedBox(height: 32),
                const Divider(),
                // درباره برنامه
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('درباره برنامه'),
                  subtitle: Text('نسخه $kAppVersion'),
                  onTap: _showAbout,
                ),
              ],
            ),
    );
  }
}
