// settings_main_page.dart
import 'package:authenticator/main.dart';
import 'package:flutter/material.dart';
import '../../services/setting_service.dart';
import 'theme.dart';

class SettingsMainPage extends StatefulWidget {
  const SettingsMainPage({super.key});

  @override
  State<SettingsMainPage> createState() => _SettingsMainPageState();
}

class _SettingsMainPageState extends State<SettingsMainPage> with RouteAware {
  final SettingsService _settingsService = SettingsService();

  final List<Map<String, dynamic>> _menuItems = const [
    {'title': '主题设置', 'subtitle': '主题风格、颜色方案', 'icon': Icons.palette},
    {'title': '关于', 'subtitle': '版本信息、开源许可', 'icon': Icons.info},
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onSettingsChanged() async {
    await MyApp.of(context)?.loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _menuItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = _menuItems[index];
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item['icon'],
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              title: Text(
                item['title'],
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(item['subtitle']),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                if (index == 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ThemeSettingsPage(
                        settingsService: _settingsService,
                        onSettingsChanged: _onSettingsChanged,
                      ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LicensePage()),
                  );
                }
              },
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
          );
        },
      ),
    );
  }
}
