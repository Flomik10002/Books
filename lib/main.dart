import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/book_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/main_screen.dart';
import 'generated/l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BookProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider(prefs)),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          // Update system UI overlay style when theme changes
          final isDark = settingsProvider.themeMode == ThemeMode.dark ||
              (settingsProvider.themeMode == ThemeMode.system &&
                  MediaQuery.of(context).platformBrightness == Brightness.dark);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            ));
          });
          
          return MaterialApp(
            title: 'Books',
            
            localizationsDelegates: const [
              S.delegate,
            ],
            supportedLocales: S.supportedLocales,
            
            // Themes
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: settingsProvider.themeMode,
            
            // Disable page transitions to prevent swipe animation
            themeAnimationDuration: Duration.zero,
            themeAnimationCurve: Curves.linear,
            
            // Set system UI overlay style based on theme
            builder: (context, child) {
              final isDark = settingsProvider.themeMode == ThemeMode.dark ||
                  (settingsProvider.themeMode == ThemeMode.system &&
                      MediaQuery.of(context).platformBrightness == Brightness.dark);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
                  systemNavigationBarColor: Colors.transparent,
                  systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
                ));
              });
              return child!;
            },
            
            home: const MainScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    const scaffold = Color(0xFFFAFAFA);
    const surface = Color(0xFFFFFFFF);
    const textColor = Color(0xFF111111);
    const secondaryText = Color(0xFF757575);

    final baseText = GoogleFonts.sourceSans3TextTheme();

    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: false,
      scaffoldBackgroundColor: scaffold,
      textTheme: baseText.apply(bodyColor: textColor, displayColor: textColor),
      colorScheme: const ColorScheme.light(
        primary: textColor,
        secondary: secondaryText,
        surface: surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textColor,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scaffold,
        foregroundColor: textColor,
        centerTitle: false,
      ),
      dividerColor: const Color(0xFFE2E2E2),
      cardColor: surface,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: textColor,
        foregroundColor: Colors.white,
        shape: StadiumBorder(),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: scaffold,
        elevation: 0,
        selectedItemColor: textColor,
        unselectedItemColor: Color(0xFF9A9A9A),
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 10),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const scaffold = Color(0xFF000000);
    const surface = Color(0xFF1C1C1C);
    const textColor = Color(0xFFFFFFFF);
    const secondaryText = Color(0xFFA1A1A1);

    final baseText = GoogleFonts.sourceSans3TextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: false,
      scaffoldBackgroundColor: scaffold,
      textTheme: baseText.apply(bodyColor: textColor, displayColor: textColor),
      colorScheme: const ColorScheme.dark(
        primary: textColor,
        secondary: secondaryText,
        surface: surface,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: textColor,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scaffold,
        foregroundColor: textColor,
        centerTitle: false,
      ),
      dividerColor: const Color(0xFF3A3A3A),
      cardColor: surface,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: StadiumBorder(),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: scaffold,
        elevation: 0,
        selectedItemColor: Colors.white,
        unselectedItemColor: Color(0xFF666666),
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 10),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}