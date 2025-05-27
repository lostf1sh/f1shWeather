import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'screens/weather_home_page.dart';
import 'screens/about_page.dart';
import 'screens/privacy_policy_page.dart';
import 'screens/terms_of_use_page.dart';

const String K_WEATHER_API_KEY = 'USE_YOUR_API_KEY';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = true;
  bool _useMetricSystem = true;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = _prefs.getBool('dark_mode') ?? true;
      _useMetricSystem = _prefs.getBool('use_metric_system') ?? true;
    });
  }

  void updateTheme(bool isDark) async {
    setState(() {
      _isDarkMode = isDark;
    });
    await _prefs.setBool('dark_mode', isDark);
  }

  void updateMetricSystem(bool useMetric) {
    setState(() {
      _useMetricSystem = useMetric;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightScheme = lightDynamic.harmonized();
          darkScheme = darkDynamic.harmonized();
        } else {
          lightScheme = ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Brightness.light,
          );
          darkScheme = ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'f1sh Weather',
          theme: _buildTheme(_isDarkMode ? darkScheme : lightScheme),
          routes: {
            '/about': (context) => const AboutPage(),
            '/privacy': (context) => const PrivacyPolicyPage(),
            '/terms': (context) => const TermsOfUsePage(),
          },
          home: WeatherHomePage(
            onThemeChanged: updateTheme,
            onMetricSystemChanged: updateMetricSystem,
            useMetricSystem: _useMetricSystem,
          ),
        );
      },
    );
  }

  ThemeData _buildTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: colorScheme.surfaceContainerHigh,
      ),
    );
  }
}