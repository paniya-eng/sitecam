import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/settings_service.dart';

/// صفحه تنظیمات — نام پروژه، متن دلخواه و گزینه‌های مُهر
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppSettings? _settings;
  late TextEditingController _projectCtrl;
  late TextEditingController _customCtrl;

  @override
  void initState() {
    super.initState();
    _projectCtrl = TextEditingController();
    _customCtrl = TextEditingController();
    SettingsService.load().then((s) {
      if (!mounted) return;
      setState(() {
        _settings = s;
        _projectCtrl.text = s.projectName;
        _customCtrl.text = s.customText;
      });
    });
  }

  @override
  void dispose() {
    _projectCtrl.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: _settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _projectCtrl,
                  decoration: const InputDecoration(
                    labelText: 'نام پروژه',
                    hintText: 'مثلاً: پروژه مسکونی سعادت‌آباد',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _settings!.projectName = v,
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
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('ذخیره تنظیمات'),
                ),
              ],
            ),
    );
  }
}
