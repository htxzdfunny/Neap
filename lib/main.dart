// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'pages/home.dart';
import 'models/settings_model.dart';
import 'services/setting_service.dart';

// 全局路由观察器
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final SettingsService _settingsService = SettingsService();
  AppSettings _currentSettings = AppSettings.defaults;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> loadSettings() async {
    final settings = await _settingsService.getSettings();
    setState(() {
      _currentSettings = settings;
      _isLoading = false;
    });
  }

  ThemeMode _getThemeMode() {
    switch (_currentSettings.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    const localizationsDelegates = [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];

    const supportedLocales = [Locale('zh', 'CH'), Locale('en', 'US')];

    if (_isLoading) {
      return const MaterialApp(
        localizationsDelegates: localizationsDelegates,
        supportedLocales: supportedLocales,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          title: 'Authenticator',
          localizationsDelegates: localizationsDelegates,
          supportedLocales: supportedLocales,
          themeMode: _getThemeMode(),
          theme: _buildTheme(
            brightness: Brightness.light,
            dynamicScheme: lightDynamic,
          ),
          darkTheme: _buildTheme(
            brightness: Brightness.dark,
            dynamicScheme: darkDynamic,
          ),
          navigatorObservers: [routeObserver],
          home: const HomePage(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }

  ThemeData _buildTheme({
    required Brightness brightness,
    ColorScheme? dynamicScheme,
  }) {
    final bool useMaterialYou = _currentSettings.useMaterialYou;
    final String pageTheme = _currentSettings.pageTheme;

    final Map<String, Color> themeColors = {
      'default': Colors.blue,
      'orange': Colors.orange,
      'green': Colors.green,
      'yellow': Colors.yellow,
      'red': Colors.red,
      'pink': Colors.pink,
      'purple': Colors.purple,
      'cyan': Colors.cyan,
      'indigo': Colors.indigo,
      'monochrome': brightness == Brightness.light
          ? Colors.black
          : Colors.white,
    };

    ColorScheme colorScheme;

    if (useMaterialYou && dynamicScheme != null) {
      colorScheme = dynamicScheme;
    } else if (pageTheme == 'monochrome') {
      if (brightness == Brightness.dark) {
        colorScheme = const ColorScheme.dark(
          primary: Colors.white,
          onPrimary: Colors.black,
          secondary: Colors.grey,
          surface: Color(0xFF121212),
        );
      } else {
        colorScheme = const ColorScheme.light(
          primary: Colors.black,
          onPrimary: Colors.white,
          secondary: Colors.grey,
          surface: Color(0xFFF5F5F5),
        );
      }
    } else {
      final seed = themeColors[pageTheme] ?? Colors.blue;
      colorScheme = ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
      );
    }

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: 'hmossans',
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
    );
  }
}
