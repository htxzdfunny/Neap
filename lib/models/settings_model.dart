class AppSettings {
  final String themeMode;
  final String pageTheme;
  final bool useMaterialYou;

  const AppSettings({
    required this.themeMode,
    required this.pageTheme,
    required this.useMaterialYou,
  });

  static const defaults = AppSettings(
    themeMode: 'system',
    pageTheme: 'default',
    useMaterialYou: false,
  );

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: json['themeMode'] ?? 'system',
      pageTheme: json['pageTheme'] ?? 'default',
      useMaterialYou: json['useMaterialYou'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode,
      'pageTheme': pageTheme,
      'useMaterialYou': useMaterialYou,
    };
  }

  AppSettings copyWith({
    String? themeMode,
    String? pageTheme,
    bool? useMaterialYou,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      pageTheme: pageTheme ?? this.pageTheme,
      useMaterialYou: useMaterialYou ?? this.useMaterialYou,
    );
  }
}
