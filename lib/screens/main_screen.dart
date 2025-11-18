import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

import '../generated/l10n.dart';
import 'library_screen.dart';
import 'reading_now_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ReadingNowScreen(),
    LibraryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    // Use adaptive bottom navigation if available, otherwise fallback to standard
    Widget bottomNav;
    if (PlatformInfo.isIOS26OrHigher()) {
      // For iOS 26+, we can use native tab bar through platform views
      // For now, use standard BottomNavigationBar with adaptive styling
      bottomNav = BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.book_outlined),
            activeIcon: const Icon(Icons.book),
            label: s.readingNowTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.library_books_outlined),
            activeIcon: const Icon(Icons.library_books),
            label: s.libraryTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: s.settingsTab,
          ),
        ],
      );
    } else {
      bottomNav = BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(PlatformInfo.isIOS ? CupertinoIcons.book : Icons.book_outlined),
            activeIcon: Icon(PlatformInfo.isIOS ? CupertinoIcons.book_fill : Icons.book),
            label: s.readingNowTab,
          ),
          BottomNavigationBarItem(
            icon: Icon(PlatformInfo.isIOS ? CupertinoIcons.book_solid : Icons.library_books_outlined),
            activeIcon: Icon(PlatformInfo.isIOS ? CupertinoIcons.book_solid : Icons.library_books),
            label: s.libraryTab,
          ),
          BottomNavigationBarItem(
            icon: Icon(PlatformInfo.isIOS ? CupertinoIcons.settings : Icons.settings_outlined),
            activeIcon: Icon(PlatformInfo.isIOS ? CupertinoIcons.settings_solid : Icons.settings),
            label: s.settingsTab,
          ),
        ],
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: bottomNav,
    );
  }
}

