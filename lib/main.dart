import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/camera_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/settings_screen.dart';

/// نقطه شروع اپ
void main() {
  runApp(const SiteCamApp());
}

class SiteCamApp extends StatelessWidget {
  const SiteCamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'سایت‌کم',
      debugShowCheckedModeBanner: false,
      // پشتیبانی از زبان فارسی و راست‌چین شدن کل رابط کاربری
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fa')],
      locale: const Locale('fa'),
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Vazirmatn',
        colorScheme: ColorScheme.fromSeed(
          // نارنجی ایمنی — مثل کلاه ایمنی کارگاه! 🦺
          seedColor: const Color(0xFFF59E0B),
          brightness: Brightness.dark,
        ),
      ),
      home: const MainShell(),
    );
  }
}

/// پوسته اصلی اپ با ناوبری بین سه صفحه:
/// دوربین | گالری | تنظیمات
///
/// در موبایل ناوبری پایین است، در تبلت و ویندوز ناوبری کناری (ریسپانسیو).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  // کلیدها برای تازه‌سازی صفحه‌ها وقتی کاربر بین تب‌ها جابه‌جا می‌شود
  final _cameraKey = GlobalKey<CameraScreenState>();
  final _galleryKey = GlobalKey<GalleryScreenState>();

  late final List<Widget> _pages = [
    CameraScreen(key: _cameraKey),
    GalleryScreen(key: _galleryKey),
    const SettingsScreen(),
  ];

  void _onTap(int i) {
    setState(() => _index = i);
    // وقتی به دوربین برمی‌گردیم، تنظیمات جدید را می‌خوانیم
    if (i == 0) _cameraKey.currentState?.refreshSettings();
    // وقتی به گالری برمی‌گردیم، عکس‌های جدید را نشان می‌دهیم
    if (i == 1) _galleryKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 700;

    // IndexedStack یعنی هر سه صفحه زنده می‌مانند و دوربین
    // با هر جابه‌جایی بین تب‌ها دوباره راه‌اندازی نمی‌شود.
    final body = IndexedStack(index: _index, children: _pages);

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _onTap,
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.camera_alt),
                  label: Text('دوربین'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.photo_library),
                  label: Text('گالری'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings),
                  label: Text('تنظیمات'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.camera_alt),
            label: 'دوربین',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library),
            label: 'گالری',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'تنظیمات',
          ),
        ],
      ),
    );
  }
}
